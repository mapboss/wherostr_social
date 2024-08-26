import 'package:flutter/material.dart';
import 'package:wherostr_social/widgets/gradient_decorated_box.dart';
import 'package:wherostr_social/widgets/profile_editing.dart';

class ProfileEditingContainer extends StatelessWidget {
  const ProfileEditingContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: const GradientDecoratedBox(
        child: ProfileEditing(),
      ),
    );
  }
}
