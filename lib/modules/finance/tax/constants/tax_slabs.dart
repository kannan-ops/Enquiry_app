/// Income Tax Slabs for FY 2024-25 (AY 2025-26)
class IncomeTaxSlab {
  final double limit;
  final double rate; // represented as percentage e.g., 5.0 for 5%

  const IncomeTaxSlab(this.limit, this.rate);
}

// New Regime Slabs (Revised in Budget 2024)
const List<IncomeTaxSlab> newRegimeSlabs = [
  IncomeTaxSlab(300000, 0),
  IncomeTaxSlab(700000, 5),
  IncomeTaxSlab(1000000, 10),
  IncomeTaxSlab(1200000, 15),
  IncomeTaxSlab(1500000, 20),
  IncomeTaxSlab(double.infinity, 30),
];

// Old Regime Slabs (Individual < 60 years)
const List<IncomeTaxSlab> oldRegimeSlabsUnder60 = [
  IncomeTaxSlab(250000, 0),
  IncomeTaxSlab(500000, 5),
  IncomeTaxSlab(1000000, 20),
  IncomeTaxSlab(double.infinity, 30),
];

// Old Regime Slabs (Senior Citizen 60 - 80 years)
const List<IncomeTaxSlab> oldRegimeSlabsSenior = [
  IncomeTaxSlab(300000, 0),
  IncomeTaxSlab(500000, 5),
  IncomeTaxSlab(1000000, 20),
  IncomeTaxSlab(double.infinity, 30),
];

// Old Regime Slabs (Super Senior Citizen 80+ years)
const List<IncomeTaxSlab> oldRegimeSlabsSuperSenior = [
  IncomeTaxSlab(500000, 0),
  IncomeTaxSlab(1000000, 20),
  IncomeTaxSlab(double.infinity, 30),
];

// Professional Tax rates per month by state
final Map<String, List<Map<String, dynamic>>> professionalTaxSlabs = {
  'Karnataka': [
    {'minSalary': 0, 'maxSalary': 24999, 'tax': 0.0},
    {'minSalary': 25000, 'maxSalary': double.infinity, 'tax': 200.0},
  ],
  'Maharashtra': [
    {'minSalary': 0, 'maxSalary': 7500, 'tax': 0.0},
    {'minSalary': 7501, 'maxSalary': 10000, 'tax': 175.0},
    {'minSalary': 10001, 'maxSalary': double.infinity, 'tax': 200.0},
  ],
  'West Bengal': [
    {'minSalary': 0, 'maxSalary': 10000, 'tax': 0.0},
    {'minSalary': 10001, 'maxSalary': 15000, 'tax': 110.0},
    {'minSalary': 15001, 'maxSalary': 25000, 'tax': 130.0},
    {'minSalary': 25001, 'maxSalary': 40000, 'tax': 150.0},
    {'minSalary': 40001, 'maxSalary': double.infinity, 'tax': 200.0},
  ],
  'Others': [
    {'minSalary': 0, 'maxSalary': 15000, 'tax': 0.0},
    {'minSalary': 15001, 'maxSalary': double.infinity, 'tax': 200.0},
  ]
};

// Road tax rate percentages by vehicle price and state
final Map<String, Map<String, Map<String, double>>> roadTaxRates = {
  'Karnataka': {
    'Two Wheeler': {'Individual': 12.0, 'Company': 15.0},
    'Four Wheeler': {'Individual': 15.0, 'Company': 20.0},
  },
  'Maharashtra': {
    'Two Wheeler': {'Individual': 10.0, 'Company': 12.0},
    'Four Wheeler': {'Individual': 12.0, 'Company': 18.0},
  },
  'Delhi': {
    'Two Wheeler': {'Individual': 8.0, 'Company': 10.0},
    'Four Wheeler': {'Individual': 10.0, 'Company': 15.0},
  },
  'Others': {
    'Two Wheeler': {'Individual': 8.0, 'Company': 10.0},
    'Four Wheeler': {'Individual': 10.0, 'Company': 12.0},
  }
};
