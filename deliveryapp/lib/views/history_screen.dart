import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/delivery_controller.dart';
import '../core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dc = Get.find<DeliveryController>();

  @override
  void initState() {
    super.initState();
    dc.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery History')),
      body: Obx(() {
        if (dc.orderHistory.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text('No deliveries yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: dc.orderHistory.length,
          itemBuilder: (_, i) {
            final o = dc.orderHistory[i];
            final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            final date = '${o.createdAt.day} ${months[o.createdAt.month]} ${o.createdAt.year}';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.shortId, style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(o.vendorName, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(date, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      if (o.deliveryDistance > 0) ...[
                        Text(' • ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Icon(Icons.directions_bike_rounded, color: AppTheme.textMuted, size: 12),
                        const SizedBox(width: 2),
                        Text('${o.deliveryDistance.toStringAsFixed(1)} km', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ]),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${o.driverEarning.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('earned', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ]),
              ]),
            );
          },
        );
      }),
    );
  }
}
