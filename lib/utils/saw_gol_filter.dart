import 'dart:math';

List<double> savitzkyGolay(List<double> data, int windowSize, int polynomialOrder, {int derivativeOrder = 0}) {
  if (data.isEmpty || windowSize <= 0 || windowSize % 2 == 0 || polynomialOrder < 0 || derivativeOrder < 0) {
    throw ArgumentError("Invalid input parameters");
  }

  int halfWindow = windowSize ~/ 2;
  int dataSize = data.length;
  List<double> smoothedData = List.filled(dataSize, 0.0);

  for (int i = 0; i < dataSize; i++) {
    double weightedSum = 0.0;
    double weightedSumOfValues = 0.0;

    for (int j = -halfWindow; j <= halfWindow; j++) {
      int index = i + j;

      if (index < 0) {
        index = 0;
      } else if (index >= dataSize) {
        index = dataSize - 1;
      }

      double weight = _calculateWeight(j, polynomialOrder, halfWindow);
      weightedSum += weight;
      weightedSumOfValues += data[index] * weight;
    }

    smoothedData[i] = weightedSumOfValues / weightedSum;
  }

  if (derivativeOrder == 0) {
    return smoothedData;
  } else if (derivativeOrder == 1) {
    List<double> derivativeData = List.filled(dataSize, 0.0);

    for (int i = halfWindow; i < dataSize - halfWindow; i++) {
      derivativeData[i] = 0.0;
      for (int j = -halfWindow; j <= halfWindow; j++) {
        derivativeData[i] += _calculateDerivativeWeight(j, polynomialOrder) * smoothedData[i + j];
      }
    }

    return derivativeData;
  } else {
    throw ArgumentError("Unsupported derivative order");
  }
}

double _calculateWeight(int position, int polynomialOrder, int halfWindow) {
  if (polynomialOrder == 0) {
    return 1.0;
  } else {
    double factor = 2.0 * polynomialOrder + 1.0;
    double weight = 0.0;

    for (int i = 0; i <= polynomialOrder; i++) {
      weight += (2 * i + 1) * pow(position, i);
    }

    return weight / factor;
  }
}

double _calculateDerivativeWeight(int position, int polynomialOrder) {
  return (factorial(polynomialOrder) * pow(-1, polynomialOrder)) / factorial(position);
}

int factorial(int n) {
  int result = 1;
  for (int i = 1; i <= n; i++) {
    result *= i;
  }
  return result;
}

// void main() {
//   List<double> data = [1.0, 2.0, 3.0, 4.0, 5.0, 4.0, 3.0, 2.0, 1.0];
//   int windowSize = 5;
//   int polynomialOrder = 2;

//   List<double> smoothedData = savitzkyGolay(data, windowSize, polynomialOrder);
//   print("Smoothed Data: $smoothedData");

//   List<double> derivativeData = savitzkyGolay(data, windowSize, polynomialOrder, derivativeOrder: 1);
//   print("First Derivative: $derivativeData");
// }
