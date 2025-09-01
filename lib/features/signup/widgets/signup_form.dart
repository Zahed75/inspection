// lib/features/authentication/screens/signup/widgets/signup_form.dart


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../common_ui/widgets/alerts/u_alert.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/texts.dart';
import '../notifier/signup_provider.dart';

class USignupForm extends ConsumerStatefulWidget {
  const USignupForm({super.key});

  @override
  ConsumerState<USignupForm> createState() => _USignupFormState();
}

class _USignupFormState extends ConsumerState<USignupForm> {
  bool _obscurePassword = true;
  bool _agreed = true;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _staffCtrl;
  late final TextEditingController _passCtrl;

  static const _designations = <String>[
    'Zonal Manager (ZM)',
    'Outlet Manager (OM)',
    'Inventory & Cash Management Officer (ICMO)',
    'Back store Manager (BSM)',
    'Manager',
    'Sales',
    'Support',
    'HR',
    'Developer',
  ];

  @override
  void initState() {
    super.initState();
    final s = ref.read(signUpProvider);
    _nameCtrl = TextEditingController(text: s.name);
    _emailCtrl = TextEditingController(text: s.email);
    _phoneCtrl = TextEditingController(text: s.phoneNumber);
    _staffCtrl = TextEditingController(text: s.staffId);
    _passCtrl = TextEditingController(text: s.password);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _staffCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // -------- Validation with UAlert --------
  bool _validateAndAlert(BuildContext context, String designation) {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final staff = _staffCtrl.text.trim();
    final pass = _passCtrl.text;

    final emailReg = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (name.isEmpty) {
      UAlert.show(
        context: context,
        title: 'Name required',
        message: 'Please enter your full name.',
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    if (email.isEmpty || !emailReg.hasMatch(email)) {
      UAlert.show(
        context: context,
        title: 'Invalid email',
        message: 'Please enter a valid email address.',
        icon: Icons.alternate_email_rounded,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    if (phone.length != 11 || !RegExp(r'^\d{11}$').hasMatch(phone)) {
      UAlert.show(
        context: context,
        title: 'Invalid phone',
        message: 'Phone number must be exactly 11 digits (e.g., 017XXXXXXXX).',
        icon: Icons.phone_iphone_rounded,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    if (staff.length != 6 || !RegExp(r'^\d{6}$').hasMatch(staff)) {
      UAlert.show(
        context: context,
        title: 'Invalid Staff ID',
        message: 'Staff ID must be exactly 6 digits.',
        icon: Icons.badge_rounded,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    if (designation.isEmpty) {
      UAlert.show(
        context: context,
        title: 'Select designation',
        message: 'Please choose your designation from the list.',
        icon: Icons.work_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    if (pass.length < 6) {
      UAlert.show(
        context: context,
        title: 'Weak password',
        message: 'Password must be at least 6 characters.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    if (!_agreed) {
      UAlert.show(
        context: context,
        title: 'Terms not accepted',
        message: 'Please agree to the Privacy Policy and Terms of Use.',
        icon: Icons.privacy_tip_outlined,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpProvider);
    final ctrl = ref.read(signUpProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Name
        TextFormField(
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: UTexts.firstName,
            prefixIcon: Icon(Iconsax.direct_right),
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // Email
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: UTexts.email,
            prefixIcon: Icon(Iconsax.direct_right),
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // Phone Number
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.call),
            prefixText: '+88 ',
            labelText: UTexts.phoneNumber,
            counterText: '',
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // Staff ID
        TextFormField(
          controller: _staffCtrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            labelText: UTexts.staffId,
            prefixIcon: Icon(Iconsax.direct_right),
            counterText: '',
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // Designation
        DropdownButtonFormField<String>(
          initialValue: state.designation.isEmpty ? null : state.designation,
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: Theme.of(context).textTheme.bodyMedium,
          items: _designations
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.user,
                        size: 18,
                        color: UColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          role,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => ctrl.updateDesignation(v ?? ''),
          decoration: InputDecoration(
            labelText: UTexts.designation,
            prefixIcon: const Icon(Iconsax.briefcase),
            filled: true,
            fillColor: isDark ? Colors.black12 : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // Password
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            prefixIcon: const Icon(Iconsax.password_check),
            labelText: UTexts.password,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Iconsax.eye : Iconsax.eye_slash),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // I agree row
        Row(
          children: [
            Checkbox(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: UTexts.iAgreeTo),
                    TextSpan(
                      text: ' ${UTexts.privacyPolicy}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? UColors.white : UColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: ' ${UTexts.and} ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextSpan(
                      text: UTexts.termsOfUse,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? UColors.white : UColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: USizes.spaceBtwItems / 2),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () {
                    // 1) Validate with UAlert
                    final ok = _validateAndAlert(
                      context,
                      ref.read(signUpProvider).designation,
                    );
                    if (!ok) return;

                    // 2) Push values to provider just-in-time
                    final ctrl = ref.read(signUpProvider.notifier);
                    ctrl.updateName(_nameCtrl.text.trim());
                    ctrl.updateEmail(_emailCtrl.text.trim());
                    ctrl.updatePhoneNumber(_phoneCtrl.text.trim());
                    ctrl.updateStaffId(_staffCtrl.text.trim());
                    ctrl.updatePassword(_passCtrl.text);

                    // 3) Call API
                    ctrl.registerUser(context);
                  },
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(UTexts.createAccount),
          ),
        ),
      ],
    );
  }
}
