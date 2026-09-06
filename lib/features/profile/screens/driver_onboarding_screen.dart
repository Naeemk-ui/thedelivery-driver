import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/driver_onboarding_model.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<ProfileController>().getOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarWidget(title: 'Verification documents'),
      body: GetBuilder<ProfileController>(builder: (controller) {
        final DriverOnboardingModel? onboarding = controller.onboarding;
        if (onboarding == null && controller.onboardingLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (onboarding == null) {
          return const Center(
              child: Text('No verification record is linked to this account.'));
        }

        return Stack(children: [
          RefreshIndicator(
            onRefresh: controller.getOnboarding,
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color: onboarding.payoutLocked
                        ? Colors.orange.withValues(alpha: 0.10)
                        : Colors.green.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(
                      color: onboarding.payoutLocked
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          onboarding.payoutLocked
                              ? 'Withdrawals are locked'
                              : 'Verification complete',
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge),
                        ),
                        const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall),
                        Text(
                          onboarding.payoutLocked
                              ? 'You can continue working. Upload every outstanding document to enable payouts.'
                              : 'Your documents are approved and payouts are available.',
                          style: robotoRegular,
                        ),
                        if (onboarding.daysRemaining != null &&
                            onboarding.payoutLocked)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: Dimensions.paddingSizeExtraSmall),
                            child: Text(
                                '${onboarding.daysRemaining} days remaining',
                                style: robotoMedium),
                          ),
                      ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                ...onboarding.documents.map(
                    (document) => _documentTile(context, controller, document)),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  'Documents are stored privately. Only limited extracted text is used for verification. Photos must be clear and show the full document.',
                  style: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor),
                ),
              ],
            ),
          ),
          if (controller.onboardingLoading)
            const Positioned.fill(
                child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            )),
        ]);
      }),
    );
  }

  Widget _documentTile(BuildContext context, ProfileController controller,
      DriverDocumentModel document) {
    final bool approved = document.status == 'approved';
    final bool queued = document.status == 'pending';
    final Color statusColor = approved
        ? Colors.green
        : queued
            ? Colors.orange
            : Colors.red;
    final String statusText = document.status.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(approved ? Icons.verified : Icons.description_outlined,
            color: statusColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(document.label, style: robotoMedium),
          Text(statusText.capitalizeFirst ?? statusText,
              style: robotoRegular.copyWith(color: statusColor)),
          if (document.rejectionReason?.isNotEmpty == true)
            Text(document.rejectionReason!,
                style: robotoRegular.copyWith(color: Colors.red)),
        ])),
        if (document.uploaded && !approved && !queued)
          IconButton(
            onPressed: () => controller.uploadOnboardingDocument(document.type),
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload document',
          ),
        if (!document.uploaded)
          TextButton.icon(
            onPressed: () => controller.uploadOnboardingDocument(document.type),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload'),
          ),
      ]),
    );
  }
}
