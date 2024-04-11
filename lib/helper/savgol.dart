import 'dart:math';
import 'package:flutter/gestures.dart';

List<double> firstDerivative(List<double> coefficients) {
  return coefficients.sublist(1).asMap().entries.map((entry) {
    return entry.value * (entry.key + 1);
  }).toList();
}

List<double> polyDerivative(List<double> coefficients, int n) {
  while (n > 0) {
    coefficients = firstDerivative(coefficients);
    n -= 1;
  }

  return coefficients;
}

double evaluatePoly(List<double> coefficients, double x) {
  double result = 0.0;
  for (int i = 0; i < coefficients.length; i++) {
    result += coefficients[i] * pow(x, i);
  }
  return result;
}

double hann(int n, int N) {
  return 0.5 * (1 - cos(2 * pi * n / (N - 1)));
}

List<double>? savgolFilter(
    {required List<double> values,
    required int windowLength,
    required int polyOrder,
    required int derivative}) {
  int halfWindow = windowLength ~/ 2;
  final paddedSize = values.length + 2 * halfWindow;
  final filteredValues = List.filled(values.length, 0.0);

  final paddedValues = List.filled(paddedSize, 0.0);

  final leadingEdgeIndices =
      List.generate(windowLength, (index) => (index + halfWindow).toDouble());
  final leadingEdgeValues = values.sublist(0, windowLength);
  final leadingEdgeFit = LeastSquaresSolver(
      leadingEdgeIndices,
      leadingEdgeValues,
      List.generate(windowLength, (index) => 1.0)).solve(polyOrder);

  final trailingEdgeIndices = List.generate(windowLength,
      (index) => (index + values.length - halfWindow - 1).toDouble());
  final trailingEdgeValues = values.sublist(values.length - windowLength);
  final trailingEdgeFit = LeastSquaresSolver(
      trailingEdgeIndices,
      trailingEdgeValues,
      List.generate(windowLength, (index) => 1.0)).solve(polyOrder);

  for (int i = 0; i < paddedValues.length; i++) {
    if (i < halfWindow) {
      if (leadingEdgeFit == null) {
        continue;
      }

      paddedValues[i] = evaluatePoly(leadingEdgeFit.coefficients, i.toDouble());
    } else if (i >= values.length + halfWindow) {
      if (trailingEdgeFit == null) {
        continue;
      }

      paddedValues[i] =
          evaluatePoly(trailingEdgeFit.coefficients, i.toDouble());
    } else {
      paddedValues[i] = values[i - halfWindow];
    }
  }

  // Schmid, Michael et al. “Why and How Savitzky-Golay Filters Should Be Replaced.”
  // ACS measurement science au vol. 2,2 (2022): 185-196. doi:10.1021/acsmeasuresciau.1c00054
  final hannWeights =
      List.generate(windowLength, (index) => hann(index, windowLength));

  for (int i = halfWindow; i < paddedValues.length - halfWindow; i++) {
    List<double> sampleX = [];
    List<double> sampleY = [];
    for (int j = 0; j < windowLength; j++) {
      sampleX.add((i + j - halfWindow).toDouble());
      sampleY.add(paddedValues[i + j - halfWindow]);
    }

    var solver = LeastSquaresSolver(sampleX, sampleY, hannWeights);
    var fit = solver.solve(polyOrder);

    if (fit == null) {
      return null;
    }

    var coefficients = polyDerivative(fit.coefficients, derivative);
    var smoothedValue = evaluatePoly(coefficients, i.toDouble());
    filteredValues[i - halfWindow] = smoothedValue;
  }

  return filteredValues;
}
