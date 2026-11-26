import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/profile/profile_controller.dart';
import '../../../controller/settings/settings_controller.dart';
import '../../../core/constant/app_image_asset.dart';
import '../../../core/constant/app_keys.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/shared/app_asset_image.dart';
import '../../../core/shared/app_divider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widget/choice_sheet.dart';
import '../../widget/circle_icon_button.dart';
import '../../widget/profile/profile_menu_tile.dart';
import '../../widget/tap_area.dart';

/// Profile tab: the guest's photo and name, the settings for language and
/// colors, and sign-out. Account features the app does not have (bookings,
/// payments, security…) are shown disabled.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  static const double avatarSize = 140;

  /// Gap between menu rows: the design's 24 minus what the 48 rows add.
  static const double rowGap = 24 - 2 * ProfileMenuTile.inset;

  void _openLanguage(BuildContext context) {
    final SettingsController settings = Get.find<SettingsController>();
    showChoiceSheet<String>(
      context,
      title: AppStrings.t(AppStrings.profileLanguage),
      selected: Localizations.localeOf(context).languageCode,
      options: <ChoiceOption<String>>[
        ChoiceOption<String>(
          value: 'en',
          label: AppStrings.t(AppStrings.profileEnglish),
        ),
        ChoiceOption<String>(
          value: 'ar',
          label: AppStrings.t(AppStrings.profileArabic),
        ),
      ],
      onSelected: (String code) => settings.changeLanguage(context, code),
    );
  }

  void _openColors(BuildContext context) {
    final SettingsController settings = Get.find<SettingsController>();
    showChoiceSheet<PaletteId>(
      context,
      title: AppStrings.t(AppStrings.profileColors),
      selected: settings.palette.value,
      options: <ChoiceOption<PaletteId>>[
        for (final PaletteId id in PaletteId.values)
          ChoiceOption<PaletteId>(
            value: id,
            label: AppStrings.t(_paletteName(id)),
            // Each palette's own logo works as its preview.
            leading: ExcludeSemantics(
              child: AppAssetImage(
                AppImageAsset.logo(id),
                width: 32.r,
                height: 32.r,
              ),
            ),
          ),
      ],
      onSelected: settings.changePalette,
    );
  }

  static String _paletteName(PaletteId id) => switch (id) {
    PaletteId.original => AppStrings.profilePaletteOriginal,
    PaletteId.purple => AppStrings.profilePalettePurple,
    PaletteId.orange => AppStrings.profilePaletteOrange,
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double gap = rowGap.h;
    final double dividerGap = (24 - ProfileMenuTile.inset).h;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: AppKeys.profileScroll,
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      AppStrings.t(AppStrings.profileTitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: palette.black1,
                      ),
                    ),
                  ),
                ),
                // Notifications are not part of this app (as on Home).
                CircleIconButton(
                  key: AppKeys.profileNotifications,
                  icon: AppIcon.notification,
                  label: AppStrings.t(AppStrings.homeNotifications),
                  onPressed: null,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            const Center(child: _Avatar()),
            SizedBox(height: 14.h),
            Text(
              AppStrings.t(AppStrings.homeGuestName),
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: palette.black1,
              ),
            ),
            SizedBox(height: 24.h),
            const AppDivider(),
            SizedBox(height: dividerGap),
            ProfileMenuTile(
              icon: AppIcon.calendar,
              label: AppStrings.t(AppStrings.profileMyBooking),
              onTap: null,
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              icon: AppIcon.wallet,
              label: AppStrings.t(AppStrings.profilePayments),
              onTap: null,
            ),
            SizedBox(height: dividerGap),
            const AppDivider(),
            SizedBox(height: dividerGap),
            ProfileMenuTile(
              icon: AppIcon.profileCurved,
              label: AppStrings.t(AppStrings.profileProfile),
              onTap: null,
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              icon: AppIcon.notificationCurved,
              label: AppStrings.t(AppStrings.profileNotification),
              onTap: null,
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              icon: AppIcon.shield,
              label: AppStrings.t(AppStrings.profileSecurity),
              onTap: null,
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              key: AppKeys.profileLanguage,
              icon: AppIcon.moreCircle,
              label: AppStrings.t(AppStrings.profileLanguage),
              onTap: () => _openLanguage(context),
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              key: AppKeys.profileColors,
              iconData: Iconsax.colorfilter_copy,
              label: AppStrings.t(AppStrings.profileColors),
              onTap: () => _openColors(context),
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              icon: AppIcon.infoSquare,
              label: AppStrings.t(AppStrings.profileHelpCenter),
              onTap: null,
            ),
            SizedBox(height: gap),
            ProfileMenuTile(
              icon: AppIcon.users,
              label: AppStrings.t(AppStrings.profileInviteFriends),
              onTap: null,
            ),
            SizedBox(height: gap),
            Obx(
              () => ProfileMenuTile(
                key: AppKeys.profileLogout,
                icon: AppIcon.logout,
                label: AppStrings.t(AppStrings.profileLogout),
                destructive: true,
                onTap: controller.isSigningOut.value
                    ? null
                    : controller.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 140 photo with the edit badge on its lower end corner. Changing the
/// photo is not part of this app, so the badge is disabled.
class _Avatar extends StatelessWidget {
  const _Avatar();

  /// The badge's 35 box sits at (105, 105) inside the photo's 140 box.
  static const double badge = 35;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double size = ProfileView.avatarSize.r;
    // The 48 touch target reaches past the badge by this much on each side.
    final double reach = (TapArea.minSize - badge.r) / 2;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          ClipOval(
            child: AppAssetImage(
              AppImageAsset.avatarPlaceholder,
              width: size,
              height: size,
              fit: BoxFit.cover,
              semanticLabel: AppStrings.t(AppStrings.homeAvatar),
            ),
          ),
          PositionedDirectional(
            end: -reach,
            bottom: -reach,
            child: TapArea(
              key: AppKeys.profileEditPhoto,
              label: AppStrings.t(AppStrings.profileEditPhoto),
              onTap: null,
              child: SizedBox.square(
                dimension: badge.r,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // The pencil is cut out of the icon; white shows through.
                    Container(width: 20.r, height: 20.r, color: palette.white),
                    AppAssetImage(
                      AppIcon.editSquare,
                      width: badge.r,
                      height: badge.r,
                      color: palette.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
