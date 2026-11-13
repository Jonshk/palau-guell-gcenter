import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

const zones = ['Entrada', 'Pasillo', 'Oficina', 'Sala de reuniones'];
const edges = <List<int>>[[0,1],[1,2],[1,3]];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(debugShowCheckedModeBanner:false,home:OfficePilot()));
}

class OfficePilot extends StatefulWidget {
  const OfficePilot({super.key});
  @override State<OfficePilot> createState()=>_OfficePilotState();
}
class _OfficePilotState extends State<OfficePilot> {
  CameraController? camera;
  Timer? timer;
  bool busy=false, training=true, locating=false;
  int locateGeneration=0;
  final List<int> recentZones=[];
  int selected=0, destination=3;
  int? position;
  double? score;
  String status='Preparando cámara';
  final Map<String,List<List<double>>> references={};
  @override void initState(){super.initState();_start();}
  Future<void> _start() async {
    try {
      final prefs=await SharedPreferences.getInstance();
      final raw=prefs.getString('office_visual_refs_v1');
      if(raw!=null){
        final parsed=jsonDecode(raw) as Map<String,dynamic>;
        for(final e in parsed.entries){
          references[e.key]=(e.value as List).map((a)=>(a as List).map((v)=>(v as num).toDouble()).toList()).toList();
        }
      }
      final cams=await availableCameras();
      final rear=cams.where((c)=>c.lensDirection==CameraLensDirection.back);
      if(rear.isEmpty) throw Exception('No hay cámara trasera');
      camera=CameraController(rear.first,ResolutionPreset.medium,enableAudio:false);
      await camera!.initialize();
      if(mounted)setState(()=>status='Listo. Referencias: ${references.values.fold<int>(0,(n,l)=>n+l.length)}');
    }catch(e){if(mounted)setState(()=>status='Error: $e');}
  }
  Future<List<double>?> _capture() async {
    if(busy||camera?.value.isInitialized!=true)return null;
    busy=true;
    try{
      final shot=await camera!.takePicture();
      final bytes=await shot.readAsBytes();
      final decoded=img.decodeImage(bytes);
      if(decoded==null)return null;
      // Miniatura de luminancia, prototipo simple (no VPR ni SLAM).
      final small=img.copyResize(decoded,width:24,height:24);
      final values=<double>[];
      for(var y=0;y<24;y++)for(var x=0;x<24;x++){
        final p=small.getPixel(x,y);
        values.add((0.299*p.r+0.587*p.g+0.114*p.b)/255.0);
      }
      final mean=values.reduce((a,b)=>a+b)/values.length;
      return values.map((v)=>v-mean).toList();
    }finally{busy=false;}
  }
  Future<void> _save() async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('office_visual_refs_v1',jsonEncode(references));
  }
  Future<void> _teach() async {
    if(locating)return;
    setState(()=>status='Capturando referencia de ${zones[selected]}...');
    final f=await _capture();
    if(f==null){setState(()=>status='No se pudo capturar');return;}
    references.putIfAbsent('$selected',()=>[]).add(f);
    await _save();
    if(mounted)setState(()=>status='Guardada referencia ${references['$selected']!.length} de ${zones[selected]}');
  }
  double _distance(List<double>a,List<double>b){
    var d=0.0;for(var i=0;i<a.length;i++){final delta=a[i]-b[i];d+=delta*delta;}
    return math.sqrt(d/a.length);
  }
  Future<void> _locate() async {
    if(!locating||references.isEmpty||busy)return;
    final generation=locateGeneration;
    final f=await _capture();if(f==null)return;
    final matches=<({int zone,double distance})>[];
    for(final e in references.entries){
      for(final sample in e.value) {
        if(sample.length==f.length)matches.add((zone:int.parse(e.key),distance:_distance(f,sample)));
      }
    }
    if(matches.isEmpty)return;
    matches.sort((a,b)=>a.distance.compareTo(b.distance));
    final best=matches.first;
    final other=matches.where((x)=>x.zone!=best.zone).toList();
    final distinct=other.isEmpty||best.distance<other.first.distance*0.78;
    // Umbral conservador, experimental. No es una probabilidad calibrada.
    final accepted=best.distance<0.13&&distinct;
    if(!mounted||!locating||generation!=locateGeneration)return;
    if(accepted){
      recentZones.add(best.zone);
      if(recentZones.length>3)recentZones.removeAt(0);
    }else{recentZones.clear();}
    final stable=recentZones.length>=2 && recentZones.every((z)=>z==best.zone);
    setState((){
      position=accepted&&stable?best.zone:null;
      score=best.distance;
      status=accepted?'Posible ubicación: ${zones[best.zone]}':'Ubicación no fiable: mueve el móvil para ver otras referencias';
    });
  }
  void _toggle(){
    if(locating){timer?.cancel();locateGeneration++;recentZones.clear();setState(()=>locating=false);return;}
    if(references.isEmpty){setState(()=>status='Primero registra referencias');return;}
    locateGeneration++;recentZones.clear();setState(()=>locating=true);
    _locate();
    timer=Timer.periodic(const Duration(seconds:3),(_)=>_locate());
  }
  List<int> _route(int start,int end){
    final q=<List<int>>[[start]];final seen=<int>{start};
    while(q.isNotEmpty){
      final path=q.removeAt(0);final last=path.last;
      if(last==end)return path;
      for(final edge in edges){
        final next=edge[0]==last?edge[1]:edge[1]==last?edge[0]:null;
        if(next!=null&&seen.add(next))q.add([...path,next]);
      }
    }
    return [];
  }
  @override void dispose(){timer?.cancel();camera?.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final route=position==null?<int>[]:_route(position!,destination);
    return Scaffold(
      appBar:AppBar(title:const Text('Indoor Nav · Oficina v0.1')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('PILOTO DE RECONOCIMIENTO VISUAL',style:TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        Text(status),const SizedBox(height:12),
        SegmentedButton<bool>(segments:const [
          ButtonSegment(value:true,label:Text('Entrenar'),icon:Icon(Icons.school)),
          ButtonSegment(value:false,label:Text('Visitante'),icon:Icon(Icons.map)),
        ],selected:{training},onSelectionChanged:(v){
          timer?.cancel();locateGeneration++;recentZones.clear();setState((){training=v.first;locating=false;position=null;});
        }),
        const SizedBox(height:16),
        if(training)...[
          const Text('Selecciona la zona que vas a enseñar:'),
          DropdownButton<int>(isExpanded:true,value:selected,items:[
            for(var i=0;i<zones.length;i++)DropdownMenuItem(value:i,child:Text(zones[i]))
          ],onChanged:(v)=>setState(()=>selected=v!)),
          FilledButton.icon(onPressed:camera?.value.isInitialized==true?_teach:null,
            icon:const Icon(Icons.camera_alt),label:const Text('Guardar referencia visual')),
          Text('Referencias en esta zona: ${references['$selected']?.length??0}'),
          const Text('Registra 5–10 vistas distintas por zona. Evita personas y objetos móviles.'),
          const SizedBox(height:8),
          Text('Total guardado: ${references.values.fold<int>(0,(n,l)=>n+l.length)} referencias'),
        ]else...[
          DropdownButton<int>(isExpanded:true,value:destination,items:[
            for(var i=0;i<zones.length;i++)DropdownMenuItem(value:i,child:Text('Destino: ${zones[i]}'))
          ],onChanged:(v)=>setState(()=>destination=v!)),
          FilledButton.icon(onPressed:camera?.value.isInitialized==true?_toggle:null,
            icon:Icon(locating?Icons.stop:Icons.location_searching),
            label:Text(locating?'Detener localización':'Iniciar localización automática')),
          const SizedBox(height:8),
          Text(position==null?'Ubicación: desconocida':'Ubicación probable: ${zones[position!]}'),
          if(score!=null)Text('Distancia visual (menor es mejor): ${score!.toStringAsFixed(3)}'),
          const SizedBox(height:12),
          const Text('MAPA ESQUEMÁTICO',style:TextStyle(fontWeight:FontWeight.bold)),
          SizedBox(height:250,child:CustomPaint(painter:OfficeMapPainter(position,destination,route))),
          Text(route.isEmpty?'Sin ruta fiable':'Ruta: ${route.map((i)=>zones[i]).join(' → ')}'),
        ],
        const SizedBox(height:18),
        const Text('Solo cámara del móvil. Sin GPS, balizas ni conexión. El método de comparación es experimental: puede confundir lugares parecidos. No es posicionamiento continuo ni debe usarse para orientación crítica.',style:TextStyle(fontSize:12,color:Colors.grey)),
      ]),
    );
  }
}
class OfficeMapPainter extends CustomPainter {
  final int? current;final int destination;final List<int> route;
  OfficeMapPainter(this.current,this.destination,this.route);
  final pts=const [Offset(.12,.25),Offset(.48,.25),Offset(.83,.25),Offset(.48,.78)];
  @override void paint(Canvas c,Size s){
    Offset p(int i)=>Offset(pts[i].dx*s.width,pts[i].dy*s.height);
    final edgePaint=Paint()..color=Colors.blueGrey.shade300..strokeWidth=5;
    for(final e in edges)c.drawLine(p(e[0]),p(e[1]),edgePaint);
    final pathPaint=Paint()..color=Colors.teal..strokeWidth=7..strokeCap=StrokeCap.round;
    for(var i=1;i<route.length;i++)c.drawLine(p(route[i-1]),p(route[i]),pathPaint);
    for(var i=0;i<pts.length;i++){
      final color=i==current?Colors.blue:i==destination?Colors.green:Colors.blueGrey;
      c.drawCircle(p(i),20,Paint()..color=color);
      final tp=TextPainter(text:TextSpan(text:'${i+1}',style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.bold)),textDirection:TextDirection.ltr)..layout();
      tp.paint(c,p(i)-Offset(tp.width/2,tp.height/2));
      final label=TextPainter(text:TextSpan(text:zones[i],style:const TextStyle(color:Colors.black,fontSize:11)),textDirection:TextDirection.ltr)..layout(maxWidth:110);
      label.paint(c,p(i)+const Offset(-30,25));
    }
  }
  @override bool shouldRepaint(covariant OfficeMapPainter old)=>old.current!=current||old.destination!=destination||old.route.join()!=route.join();
}
