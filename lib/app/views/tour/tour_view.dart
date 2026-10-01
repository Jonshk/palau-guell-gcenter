import '/config.dart';

class TourView extends StatelessWidget {
  final List<Tour> _tours = services.tours.list;

  TourView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(showBackButton: true, title: "i18n.tours".tr),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: _tours.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => TourCard(tour: _tours[index]),
      ),
      backgroundColor: AppTheme.light,
    );
  }
}
