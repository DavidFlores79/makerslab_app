import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';

import '../../../../di/service_locator.dart';
import '../../../catalogs/data/models/country_model.dart';
import '../../../catalogs/domain/usecases/get_countries.dart';

class AppCountryDropdown extends StatefulWidget {
  final String? labelText;
  final String? errorText;
  final Function(CountryModel?)? onChanged;
  final CountryModel? initialCountry;
  final String? initialCountryCode;
  final FormFieldValidator<CountryModel>? validator;

  const AppCountryDropdown({
    super.key,
    this.labelText,
    this.errorText,
    this.onChanged,
    this.initialCountry,
    this.initialCountryCode,
    this.validator,
  });

  @override
  State<AppCountryDropdown> createState() => _AppCountryDropdownState();
}

class _AppCountryDropdownState extends State<AppCountryDropdown> {
  List<CountryModel> _countries = [];
  CountryModel? _selectedCountry;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getCountries = getIt<GetCountries>();
    final result = await getCountries();

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = failure.message;
          });
        }
      },
      (countries) {
        if (mounted) {
          setState(() {
            _countries = countries;
            _isLoading = false;

            // Determine which country to select
            if (_selectedCountry == null) {
              String targetCode = 'MX'; // default

              // Check if we have an initial country code from user data
              if (widget.initialCountryCode != null &&
                  widget.initialCountryCode!.isNotEmpty) {
                targetCode = widget.initialCountryCode!.toUpperCase();
              } else if (widget.initialCountry != null) {
                targetCode = widget.initialCountry!.code?.toUpperCase() ?? 'MX';
              }

              // Find the country that matches the target code
              _selectedCountry = countries.firstWhere(
                (country) => country.code?.toUpperCase() == targetCode,
                orElse:
                    () => countries.firstWhere(
                      (country) => country.code?.toUpperCase() == 'MX',
                      orElse:
                          () =>
                              countries.isNotEmpty
                                  ? countries.first
                                  : countries[0],
                    ),
              );

              // Notify parent of the selection
              if (_selectedCountry != null && widget.onChanged != null) {
                widget.onChanged!(_selectedCountry);
              }
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Country',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
        ),
        child: const SizedBox(
          height: 24,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Country',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
          errorText: _error,
          errorMaxLines: 2,
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load countries',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _fetchCountries,
              tooltip: 'Retry',
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<CountryModel>(
      value: _selectedCountry,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Country',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 16,
        ),
        errorText: widget.errorText,
      ),
      isExpanded: true,
      validator: widget.validator,
      items:
          _countries.map((CountryModel country) {
            return DropdownMenuItem<CountryModel>(
              value: country,
              child: Row(
                children: [
                  CircleFlag(country.code?.toLowerCase() ?? 'xx', size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      country.name ?? 'Unknown',
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _getPhoneCode(country),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (CountryModel? newValue) {
        setState(() {
          _selectedCountry = newValue;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      },
      selectedItemBuilder: (BuildContext context) {
        return _countries.map<Widget>((CountryModel country) {
          return Row(
            children: [
              CircleFlag(country.code?.toLowerCase() ?? 'xx', size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  country.name ?? 'Unknown',
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList();
      },
    );
  }

  String _getPhoneCode(CountryModel country) {
    final phoneCode = country.phoneCode ?? '';
    if (phoneCode.isEmpty) return '';
    // validate if phoneCode has '+' don't add another '+'
    if (phoneCode.startsWith('+')) {
      return phoneCode;
    } else {
      return '+$phoneCode';
    }
  }
}
