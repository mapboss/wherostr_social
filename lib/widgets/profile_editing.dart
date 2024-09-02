import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:text_parser/text_parser.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/services/file.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/text_parser.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';

class ProfileEditing extends StatefulWidget {
  final String? submitButtonLabel;
  final void Function()? onBeforeSubmit;
  final Future<void> Function({
    String? picture,
    String? banner,
    String? name,
    String? displayName,
    String? about,
    String? website,
    String? lud06,
    String? lud16,
    String? nip05,
  })? onSubmit;

  const ProfileEditing({
    super.key,
    this.submitButtonLabel,
    this.onBeforeSubmit,
    this.onSubmit,
  });

  @override
  State<ProfileEditing> createState() => _ProfileEditingState();
}

class _ProfileEditingState extends State<ProfileEditing> {
  final _formKey = GlobalKey<FormState>();
  final RegExp _emailPattern = RegExp(const EmailMatcher().pattern);
  final RegExp _linkPattern = RegExp(const UrlLikeMatcher().pattern);
  final RegExp _lnurlPattern =
      RegExp(const LightningUrlMatcher().pattern, caseSensitive: false);

  String? _picture;
  File? _pictureFile;
  String? _banner;
  File? _bannerFile;
  String? _displayName;
  String? _about;
  String? _website;
  String? _lud16Or06;
  String? _nip05;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final me = context.read<AppStatesProvider>().me;
    _picture = me.picture;
    _banner = me.banner;
    _displayName = me.rawDisplayName;
    _about = me.about;
    _website = me.website;
    _lud16Or06 = me.lud16 ?? me.lud06;
    _nip05 = me.nip05;
  }

  Future<void> _handlePictureChooseFromLibraryPressed() async {
    try {
      _addPicturePhoto(await FileService.pickAPhoto());
    } catch (error) {
      AppUtils.handleError();
    }
  }

  Future<void> _handlePictureTakeAPhotoPressed() async {
    try {
      _addPicturePhoto(await FileService.takeAPhoto());
    } catch (error) {
      AppUtils.handleError();
    }
  }

  void _handleRemovePicturePressed() {
    setState(() {
      _picture = null;
      _pictureFile = null;
    });
  }

  Future<void> _handleBannerChooseFromLibraryPressed() async {
    try {
      _addBannerPhoto(await FileService.pickAPhoto());
    } catch (error) {
      AppUtils.handleError();
    }
  }

  Future<void> _handleBannerTakeAPhotoPressed() async {
    try {
      _addBannerPhoto(await FileService.takeAPhoto());
    } catch (error) {
      AppUtils.handleError();
    }
  }

  void _handleRemoveBannerPressed() {
    setState(() {
      _banner = null;
      _bannerFile = null;
    });
  }

  Future<void> _addPicturePhoto(XFile? file) async {
    if (file != null) {
      setState(() {
        _pictureFile = File(file.path);
      });
    }
  }

  Future<void> _addBannerPhoto(XFile? file) async {
    if (file != null) {
      setState(() {
        _bannerFile = File(file.path);
      });
    }
  }

  void _save() async {
    try {
      if (_formKey.currentState!.validate()) {
        widget.onBeforeSubmit?.call();
        setState(() {
          _isLoading = true;
        });
        _formKey.currentState!.save();
        String? picture = _picture;
        String? banner = _banner;
        List<File> files = [];
        if (_pictureFile != null) {
          files.add(_pictureFile!);
        }
        if (_bannerFile != null) {
          files.add(_bannerFile!);
        }
        if (files.isNotEmpty) {
          AppUtils.showSnackBar(
            text:
                'Uploading ${files.length} image${files.length > 1 ? 's' : ''}...',
            withProgressBar: true,
            autoHide: false,
          );
          final fileUrls = await FileService.uploadMultiple(files);
          if (_pictureFile != null) {
            picture = fileUrls[0].url;
            setState(() {
              _picture = picture;
              _pictureFile = null;
            });
          }
          if (_bannerFile != null) {
            banner = fileUrls[fileUrls.length - 1].url;
            setState(() {
              _banner = banner;
              _bannerFile = null;
            });
          }
          AppUtils.hideSnackBar();
        }
        String? lud06;
        String? lud16;
        if (_lud16Or06 != null) {
          if (_emailPattern.hasMatch(_lud16Or06!)) {
            lud16 = _lud16Or06;
          } else if (_lnurlPattern.hasMatch(_lud16Or06!)) {
            lud06 = _lud16Or06;
          }
        }
        if (widget.onSubmit == null) {
          if (mounted) {
            AppUtils.showSnackBar(
              text: 'Updating...',
              withProgressBar: true,
              autoHide: false,
            );
            final appState = context.read<AppStatesProvider>();
            await appState.updateProfile(
              picture: picture,
              banner: banner,
              name: _displayName?.isEmpty == true
                  ? null
                  : _displayName?.toSnakeCase(),
              displayName: _displayName?.isEmpty == true ? null : _displayName,
              about: _about,
              website: _website,
              lud16: lud16,
              lud06: lud06,
              nip05: _nip05,
              relays: appState.me.relayList,
            );
            AppUtils.showSnackBar(
              text: 'Updated successfully.',
              status: AppStatus.success,
            );
          } else {
            AppUtils.hideSnackBar();
          }
        } else {
          await widget.onSubmit!(
            picture: picture,
            banner: banner,
            name: _displayName?.toSnakeCase(),
            displayName: _displayName,
            about: _about,
            website: _website,
            lud16: lud16,
            lud06: lud06,
            nip05: _nip05,
          );
        }
      }
    } catch (error) {
      AppUtils.hideSnackBar();
      AppUtils.handleError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final bannerFile =
        _bannerFile == null ? null : Image.file(_bannerFile!).image;
    final pictureFile =
        _pictureFile == null ? null : Image.file(_pictureFile!).image;
    return PopScope(
      canPop: !_isLoading,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _banner == null && bannerFile == null
                          ? wherostrBackgroundDecoration
                          : BoxDecoration(
                              image: DecorationImage(
                                image: bannerFile ??
                                    AppUtils.getImageProvider(_banner!),
                                fit: BoxFit.cover,
                              ),
                            ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: ProfileAvatar(
                              image: pictureFile,
                              url: _picture,
                              borderSize: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              MenuAnchor(
                                builder: (BuildContext context,
                                    MenuController controller, Widget? child) {
                                  return OutlinedButton.icon(
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                    icon: const Icon(Icons.account_circle),
                                    label: const Text('Profile picture'),
                                  );
                                },
                                menuChildren: [
                                  MenuItemButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handlePictureChooseFromLibraryPressed,
                                    leadingIcon: const Icon(
                                      Icons.photo,
                                    ),
                                    child: const Text(
                                      'Choose from library',
                                    ),
                                  ),
                                  MenuItemButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handlePictureTakeAPhotoPressed,
                                    leadingIcon: const Icon(
                                      Icons.camera_alt,
                                    ),
                                    child: const Text(
                                      'Take photo',
                                    ),
                                  ),
                                  if (_picture != null || _pictureFile != null)
                                    MenuItemButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleRemovePicturePressed,
                                      leadingIcon: Icon(
                                        Icons.delete,
                                        color: themeData.colorScheme.error,
                                      ),
                                      child: Text(
                                        'Remove',
                                        style: TextStyle(
                                            color: themeData.colorScheme.error),
                                      ),
                                    ),
                                ],
                              ),
                              MenuAnchor(
                                builder: (BuildContext context,
                                    MenuController controller, Widget? child) {
                                  return OutlinedButton.icon(
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                    icon: const Icon(Icons.panorama),
                                    label: const Text('Banner'),
                                  );
                                },
                                menuChildren: [
                                  MenuItemButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleBannerChooseFromLibraryPressed,
                                    leadingIcon: const Icon(
                                      Icons.photo,
                                    ),
                                    child: const Text(
                                      'Choose from library',
                                    ),
                                  ),
                                  MenuItemButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleBannerTakeAPhotoPressed,
                                    leadingIcon: const Icon(
                                      Icons.camera_alt,
                                    ),
                                    child: const Text(
                                      'Take photo',
                                    ),
                                  ),
                                  if (_banner != null || _bannerFile != null)
                                    MenuItemButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleRemoveBannerPressed,
                                      leadingIcon: Icon(
                                        Icons.delete,
                                        color: themeData.colorScheme.error,
                                      ),
                                      child: Text(
                                        'Remove',
                                        style: TextStyle(
                                            color: themeData.colorScheme.error),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                            child: Text(
                              'Name',
                              style: themeData.textTheme.titleMedium!
                                  .copyWith(color: themeExtension.textDimColor),
                            ),
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              filled: true,
                            ),
                            readOnly: _isLoading,
                            initialValue: _displayName,
                            onSaved: (newValue) => _displayName = newValue,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                            child: Text(
                              'About',
                              style: themeData.textTheme.titleMedium!
                                  .copyWith(color: themeExtension.textDimColor),
                            ),
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              hintText: "Say something about yourself.",
                              hintStyle: TextStyle(
                                color: themeExtension.textDimColor,
                              ),
                            ),
                            maxLines: 3,
                            readOnly: _isLoading,
                            initialValue: _about,
                            onSaved: (newValue) => _about = newValue,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                            child: Text(
                              'Link',
                              style: themeData.textTheme.titleMedium!
                                  .copyWith(color: themeExtension.textDimColor),
                            ),
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              hintText: "Enter your website.",
                              hintStyle: TextStyle(
                                color: themeExtension.textDimColor,
                              ),
                            ),
                            readOnly: _isLoading,
                            initialValue: _website,
                            onSaved: (newValue) => _website = newValue,
                            onChanged: (value) =>
                                _formKey.currentState?.validate(),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (_linkPattern.hasMatch(value)) return null;
                              return 'Invalid link';
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                            child: Text(
                              'Verified Nostr Address (NIP-05)',
                              style: themeData.textTheme.titleMedium!
                                  .copyWith(color: themeExtension.textDimColor),
                            ),
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              hintText: "ex. nostr@example.com",
                              hintStyle: TextStyle(
                                color: themeExtension.textDimColor,
                              ),
                            ),
                            readOnly: _isLoading,
                            initialValue: _nip05,
                            onSaved: (newValue) => _nip05 = newValue,
                            onChanged: (value) =>
                                _formKey.currentState?.validate(),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (_emailPattern.hasMatch(value)) return null;
                              return 'Invalid address';
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                            child: Text(
                              'Bitcoin Lightning Address',
                              style: themeData.textTheme.titleMedium!
                                  .copyWith(color: themeExtension.textDimColor),
                            ),
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              hintText: "ex. lightning@example.com",
                              hintStyle: TextStyle(
                                color: themeExtension.textDimColor,
                              ),
                            ),
                            readOnly: _isLoading,
                            initialValue: _lud16Or06,
                            onSaved: (newValue) => _lud16Or06 = newValue,
                            onChanged: (value) =>
                                _formKey.currentState?.validate(),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (_emailPattern.hasMatch(value) ||
                                  _lnurlPattern.hasMatch(value)) return null;
                              return 'Invalid address';
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            elevation: 1,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Center(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _isLoading ? null : _save,
                    child: Text(widget.submitButtonLabel ?? 'Save'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
