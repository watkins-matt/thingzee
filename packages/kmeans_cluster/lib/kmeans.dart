import 'dart:math';

/// Represents a cluster of data points with
/// a mean and members identified by their keys
class Cluster {
  /// Unique identifier for the cluster
  final int id;

  // A mapping of keys to their corresponding data points in the cluster
  final Map<String, double> data = {};

  /// Creates a [Cluster] with a given [id]
  Cluster(this.id);

  /// The mean value of the data points in the cluster, calculated on demand
  double get mean {
    if (data.isEmpty) return 0;
    return data.values.reduce((a, b) => a + b) / data.length;
  }

  /// Gets a set of all member keys in the cluster
  Set<String> get members => data.keys.toSet();

  /// The sum of the squared distances from each data point to the cluster's mean
  double get sumSquaredDistances {
    return data.values.fold(0, (sum, value) => sum + pow(value - mean, 2).toDouble());
  }

  /// Adds a data point to the cluster with the provided [key] and [value]
  void add(String key, double value) {
    data[key] = value;
  }

  /// Calculates the Euclidean distance to another cluster based on mean values
  double distanceTo(Cluster other) {
    return (mean - other.mean).abs();
  }

  @override
  String toString() => 'Cluster $id (mean: $mean, members: ${data.keys.toList()})';
}

/// A class that performs K-Means clustering on a set of data points
class KMeansClusterer {
  /// The data points to be clustered, mapped by their keys
  final Map<String, double> data;

  /// The list of clusters created after the clustering process
  List<Cluster> clusters = [];

  /// An index to quickly find the cluster for a given key
  Map<String, Cluster> index = {};
  final int maxIterations;
  final double tolerance;
  final Random rng;

  /// Creates a [KMeansClusterer] with the provided [data], [maxIterations], [tolerance], and random [seed]
  KMeansClusterer(this.data, {this.maxIterations = 300, this.tolerance = 1e-4, int? seed = 50})
      : rng = Random(seed);

  List<Cluster> get outliers {
    // Calculate the average number of data points per cluster
    final double meanDataPointsPerCluster =
        clusters.fold(0, (sum, cluster) => sum + cluster.members.length) / clusters.length;

    // Calculate the median of the cluster means
    final double medianClusterMeans = _median(clusters.map((c) => c.mean).toList());

    // Cluster is sparse if its size is less than 30% of the average size
    const double sparsityThreshold = 0.3;
    // Cluster's mean is high if it's more than 200% of the median mean
    const double meanValueThreshold = 2;

    // Identify clusters that are outliers based on sparsity or mean value
    List<Cluster> outliers = clusters
        .where((cluster) =>
            cluster.members.length < meanDataPointsPerCluster * sparsityThreshold ||
            cluster.mean > medianClusterMeans * meanValueThreshold)
        .toList();

    return outliers;
  }

  /// Converts the map of data points into a list of lists for K-Means processing
  List<List<double>> get points => data.values.map((e) => [e]).toList();

  /// Retrieves the cluster for the provided [key], if it exists
  Cluster? operator [](String key) => index[key];

  void cluster([int? k]) {
    // If there is no data, return without clustering
    if (data.isEmpty) {
      clusters = [];
      index = {};
      return;
    }

    // If there's only one data point, we create one cluster with that point and return
    if (data.length == 1) {
      String key = data.keys.first;
      clusters = [Cluster(0)];
      clusters.first.add(key, data[key]!);
      index = {key: clusters.first};
      return;
    }

    // If there are two data points, determine if they are close enough to be in the same cluster
    if (data.length == 2) {
      List<double> values = data.values.toList();
      double minVal = values.reduce(min);
      double maxVal = values.reduce(max);
      int numberOfClusters = maxVal < 2 * minVal ? 1 : 2;
      List<double> centroids = _initializeCentroids(numberOfClusters);
      _performClustering(centroids);
      return;
    }

    // If `k` is not provided, find the optimal number of clusters, otherwise use the given `k`
    int numberOfClusters = k ?? findOptimalK(data, min(data.length, 20));
    List<double> centroids = _initializeCentroids(numberOfClusters);
    _performClustering(centroids);
  }

  int findOptimalK(Map<String, double> data, int maxK) {
    int optimalK = 1;
    double highestSilhouetteScore = double.negativeInfinity;

    for (int k = 2; k <= maxK; k++) {
      List<double> centroids = _initializeCentroids(k);
      _performClustering(centroids);
      double averageSilhouetteScore = _calculateAverageSilhouetteScore();

      if (averageSilhouetteScore > highestSilhouetteScore) {
        highestSilhouetteScore = averageSilhouetteScore;
        optimalK = k;
      }
    }

    return optimalK;
  }

  void _assignDataToClusters(List<double> centroids, int k) {
    clusters = List.generate(k, (index) => Cluster(index));
    index.clear();

    data.forEach((key, value) {
      int closestCentroidIndex = _findClosestCentroid(value, centroids);
      clusters[closestCentroidIndex].add(key, value);
      index[key] = clusters[closestCentroidIndex];
    });
  }

  double _averageIntraClusterDistance(String key, Cluster cluster) {
    double sum = cluster.data.values
        .fold(0, (previous, value) => previous + (value - cluster.data[key]!).abs());
    return sum / (cluster.data.length - 1);
  }

  double _averageNearestClusterDistance(String key, Cluster cluster) {
    double nearestDistance = double.infinity;

    for (final otherCluster in clusters.where((c) => c.id != cluster.id)) {
      double distance = otherCluster.data.values
          .fold(0, (previous, value) => previous + (value - cluster.data[key]!).abs());
      double averageDistance = distance / otherCluster.data.length;

      if (averageDistance < nearestDistance) {
        nearestDistance = averageDistance;
      }
    }

    return nearestDistance;
  }

  double _calculateAverageSilhouetteScore() {
    double totalScore = 0;
    int count = 0;

    for (final cluster in clusters) {
      for (final key in cluster.members) {
        totalScore += _silhouetteScore(key, cluster);
        count++;
      }
    }

    return count > 0 ? totalScore / count : 0.0;
  }

  int _findClosestCentroid(double value, List<double> centroids) {
    int closestIndex = 0;
    double closestDistance = double.maxFinite;

    for (int i = 0; i < centroids.length; i++) {
      double distance = (value - centroids[i]).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  List<double> _initializeCentroids(int k) {
    List<double> initialCentroids = [];
    List<double> shuffledData = data.values.toList()..shuffle(rng);

    for (int i = 0; i < k; i++) {
      initialCentroids.add(shuffledData[i]);
    }

    return initialCentroids;
  }

  double _median(List<double> numbers) {
    // Create a copy of the list to avoid side effects
    List<double> sortedNumbers = List.from(numbers)..sort();

    // Find the median value
    int middle = sortedNumbers.length ~/ 2;
    if (sortedNumbers.length % 2 == 1) {
      return sortedNumbers[middle];
    } else {
      return (sortedNumbers[middle - 1] + sortedNumbers[middle]) / 2.0;
    }
  }

  void _performClustering(List<double> centroids) {
    bool changed;
    int iterations = 0;
    int k = centroids.length; // Number of clusters

    do {
      _assignDataToClusters(centroids, k);
      changed = _recalculateCentroids(centroids, k);
      iterations++;
    } while (changed && iterations < maxIterations);
  }

  bool _recalculateCentroids(List<double> centroids, int k) {
    bool changed = false;

    for (int i = 0; i < k; i++) {
      double oldCentroid = centroids[i];
      double newCentroid = clusters[i].mean;
      centroids[i] = newCentroid;

      if ((newCentroid - oldCentroid).abs() > tolerance) {
        changed = true;
      }
    }

    return changed;
  }

  double _silhouetteScore(String key, Cluster cluster) {
    double a = _averageIntraClusterDistance(key, cluster);
    double b = _averageNearestClusterDistance(key, cluster);
    return (b - a) / max(a, b);
  }
}
