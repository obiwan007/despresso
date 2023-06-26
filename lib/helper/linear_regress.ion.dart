// Import math library
import 'dart:math';

// Define a class for data points
class DataPoint {
  double x;
  double y;
  DataPoint(this.x, this.y);
}

class Line {
  double m;
  double b;
  Line(this.m, this.b);
  static Line limit(Line l) {
    double b = max(-100, min(l.b, 100));
    double m = max(-10, min(l.m, 10));
    if (m == 0.0) {
      m = 0.001;
    }
    return Line(m, b);
  }
}

// Define a function to calculate linear regression
/// Es verwendet die Methode der kleinsten Quadrate, um die Koeffizienten der
/// Ausgleichsgerade zu finden2. Das Programm nimmt eine Liste von Datenpunkten
/// als Eingabe und gibt die Gleichung der Ausgleichsgerade als Ausgabe aus.
Line linearRegression(List<DataPoint> data) {
  // Initialize variables
  int n = data.length;
  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumXX = 0;

  // Loop through the data points and calculate sums
  for (DataPoint p in data) {
    sumX += p.x;
    sumY += p.y;
    sumXY += p.x * p.y;
    sumXX += p.x * p.x;
  }

  // Calculate the coefficients of the regression line
  double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  double intercept = (sumY - slope * sumX) / n;

  // Return the equation of the regression line
  return Line(slope, intercept);
  // return "y = ${slope.toStringAsFixed(2)}x + ${intercept.toStringAsFixed(2)}";
}

// // Define some sample data points
// List<DataPoint> sampleData = [
//   DataPoint(1, 2),
//   DataPoint(2, 4),
//   DataPoint(3, 5),
// ];

// // Call the linear regression function and print the result
// print(linearRegression(sampleData));

// Define a function to calculate linear regression

/// Es verwendet die Gradientenabstiegsmethode, um die Koeffizienten der
/// Ausgleichsgerade zu finden1. Das Programm nimmt eine Liste von Datenpunkten
/// als Eingabe und gibt die Gleichung der Ausgleichsgerade als Ausgabe aus.
Line linearRegressionViaGradient(List<DataPoint> data) {
  // Initialize variables
  int n = data.length;
  double alpha = 0.01; // Learning rate
  double epsilon = 0.01; // Convergence criterion
  double slope = 0; // Initial guess for slope
  double intercept = 0; // Initial guess for intercept
  double error = double.infinity; // Initial value for error

  // Loop until convergence or maximum iterations
  int maxIterations = 100;
  int iteration = 0;

  while (error > epsilon && iteration < maxIterations) {
    // Initialize gradients
    double slopeGradient = 0;
    double interceptGradient = 0;

    // Loop through the data points and calculate gradients
    for (DataPoint p in data) {
      slopeGradient += -2 * p.x * (p.y - (slope * p.x + intercept));
      interceptGradient += -2 * (p.y - (slope * p.x + intercept));
    }

    // Update the coefficients using gradient descent
    slope = slope - alpha * slopeGradient / n;
    intercept = intercept - alpha * interceptGradient / n;

    // Calculate the mean squared error
    error = 0;
    for (DataPoint p in data) {
      error += pow(p.y - (slope * p.x + intercept), 2);
    }
    error /= n;

    // Increment the iteration counter
    iteration++;
  }

  // if (iteration == maxIterations) {
  //   print("Maximum iterations reached");
  // } else {
  //   print("Converged in $iteration iterations");
  // }
  return Line(slope, intercept);
  // return "y = ${slope.toStringAsFixed(2)}x + ${intercept.toStringAsFixed(2)}";
}
