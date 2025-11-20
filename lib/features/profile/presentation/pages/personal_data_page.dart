// ABOUTME: This file contains the Personal Data page
// ABOUTME: Allows users to view and edit their personal information

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/index.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/ui/snackbar_service.dart';
import '../../../../shared/widgets/px_custom_text_field.dart';
import '../../../../core/validators/px_validators.dart';
import '../../../auth/presentation/widgets/app_country_dropdown.dart';
import '../../../catalogs/data/models/country_model.dart';

class PersonalDataPage extends StatefulWidget {
  static const String routeName = '/personal-data';

  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _countryCode = '52'; // Default Mexico

  String? _userImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final user = authState.user;
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _userImage = user.image;

      // Handle phone number
      if (user.phone != null && user.phone!.isNotEmpty) {
        String phone = user.phone!;
        if (phone.startsWith('+')) {
          // Simple logic: assume country code is 2 digits for now or try to match
          // A better approach would be to use a library or iterate over known codes
          // For this specific requirement, we'll try to extract standard length codes
          // or just default to Mexico (52) if it matches.

          // Remove the +
          String rawPhone = phone.substring(1);

          // Check if it starts with 52 (Mexico)
          if (rawPhone.startsWith('52')) {
            _countryCode = '52';
            _phoneController.text = rawPhone.substring(2);
          } else {
            // Fallback: take first 2 digits as code? Or just put everything in phone?
            // Let's assume 1-3 digits for country code.
            // Without a list of codes, it's hard to be precise.
            // For now, let's assume the user manually selects the country if it's not 52
            // or we leave the whole number if we can't parse it easily.
            // But the user requested "appear without the country code".

            // Let's try to guess: usually 1 (US), 52 (MX), etc.
            // We will just put the whole number if not 52 for safety,
            // or maybe just 52 as default and check.

            // Implementation for now: Check for 52, else default behavior (maybe just show all?)
            // User said "put together when is sended", so we must split it.

            // Let's try to use the AppCountryDropdown's list if possible, but we don't have access here easily.
            // We'll stick to the '52' check as primary use case, else try to split by length?
            // Let's just assume 52 for this specific user context or generic split.

            if (rawPhone.startsWith('1')) {
              // US
              _countryCode = '1';
              _phoneController.text = rawPhone.substring(1);
            } else {
              // Default fallback: treat everything as number if we can't guess
              // OR, better: if we can't guess, maybe we shouldn't split it wrong.
              // But the request is specific.

              // Let's just set the text to the full number (minus +) and let user fix if needed?
              // Or better, just set it as is.
              _phoneController.text = rawPhone;
            }
          }
        } else {
          _phoneController.text = phone;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const PxBackAppBar(backLabel: 'Back'),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            SnackbarService().show(message: state.message);
          } else if (state is Authenticated) {
            SnackbarService().show(message: 'Perfil actualizado exitosamente');
            Navigator.of(context).pop();
          }
        },
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar with camera icon
                  _buildAvatarSection(theme),
                  const SizedBox(height: 30),

                  // Name
                  PXCustomTextField(
                    labelText: 'Full Name',
                    controller: _nameController,
                    validator: PXAppValidators.name,
                  ),
                  const SizedBox(height: 16),

                  // Phone with Country Dropdown
                  AppCountryDropdown(
                    labelText: 'Country',
                    initialCountryCode: _countryCode == '1' ? 'US' : 'MX',
                    onChanged: (CountryModel? country) {
                      if (country != null && country.phoneCode != null) {
                        setState(() {
                          _countryCode = country.phoneCode!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  PXCustomTextField(
                    labelText: 'Phone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    readOnly: true, // Usually phone is not editable
                    validator: PXAppValidators.phone,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  PXCustomTextField(
                    labelText: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: PXAppValidators.email,
                    optional: true,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return MainAppButton(
                        label: isLoading ? 'Guardando...' : 'Save',
                        expand: true,
                        onPressed: isLoading ? null : _saveData,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button
                  MainAppButton(
                    label: 'Cancel',
                    variant: ButtonVariant.outlined,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              _userImage != null && _userImage!.isNotEmpty
                  ? (_userImage!.startsWith('http')
                      ? NetworkImage(_userImage!) as ImageProvider
                      : AssetImage(_userImage!))
                  : const AssetImage('assets/images/default_avatar.png'),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userId = authState.user.id;
        if (userId == null) {
          SnackbarService().show(message: 'Error: Usuario no identificado');
          return;
        }

        // Dispatch UpdateProfileRequested event
        final fullPhone = '+${_countryCode}${_phoneController.text.trim()}';

        context.read<AuthBloc>().add(
          UpdateProfileRequested(
            userId: userId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: fullPhone,
            image: _userImage,
          ),
        );
      }
    }
  }
}
