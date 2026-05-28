#include <Rcpp.h>
#include <cmath>
#include <numeric>
#include <vector>
using namespace Rcpp;

// Custom model placeholder:
// Replace this function body when designing your own accumulation process.
// Keep the minimal output convention (item_idx and rt) stable.
// [[Rcpp::export]]
List accumulate_evidence_custom_model(
  NumericVector A,
  NumericVector step_size,
  NumericVector Z,
  NumericVector ndt,
  double max_t,
  double dt,
  int max_reached,
  Function noise_func = R_NilValue
) {
  int n_items = step_size.size();

  if (A.size() != n_items || Z.size() != n_items || ndt.size() != n_items) {
    stop("A, step_size, Z, and ndt must have length n_items");
  }
  if (max_reached <= 0 || max_reached > n_items) {
    stop("max_reached must be > 0 and <= n_items");
  }
  if (dt <= 0 || max_t <= 0) {
    stop("dt and max_t must be > 0");
  }
  if (Rf_isNull(noise_func)) {
    stop("noise_func parameter is required and cannot be NULL");
  }

  std::vector<int> active_item_idx(n_items);
  std::vector<double> evidence(Z.begin(), Z.end());
  std::vector<double> passed_t(ndt.begin(), ndt.end());
  std::vector<double> step(step_size.begin(), step_size.end());
  std::iota(active_item_idx.begin(), active_item_idx.end(), 0);

  std::vector<int> reached_item_idx;
  std::vector<double> rt;
  std::vector<double> reached_evidence;
  reached_item_idx.reserve(max_reached);
  rt.reserve(max_reached);
  reached_evidence.reserve(max_reached);

  int n_reached = 0;
  int step_idx = 0;
  double t = 0.0;

  while (!evidence.empty() && n_reached < max_reached && t < max_t) {
    step_idx++;
    t += dt;
    double direction = (step_idx % 2 == 1) ? -1.0 : 1.0;
    NumericVector noise = as<NumericVector>(noise_func(evidence.size(), dt));
    if (static_cast<size_t>(noise.size()) != evidence.size()) {
      stop("noise_func must return one noise value for each active item");
    }

    for (size_t i = 0; i < evidence.size(); i++) {
      evidence[i] += direction * step[i] * std::abs(noise[i]);
      passed_t[i] += dt;
    }

    for (size_t i = 0; i < evidence.size(); i++) {
      if (evidence[i] >= A[active_item_idx[i]]) {
        reached_item_idx.push_back(active_item_idx[i] + 1);
        rt.push_back(passed_t[i]);
        reached_evidence.push_back(evidence[i]);
        n_reached++;

        size_t last_idx = evidence.size() - 1;
        if (i != last_idx) {
          std::swap(active_item_idx[i], active_item_idx[last_idx]);
          std::swap(evidence[i], evidence[last_idx]);
          std::swap(passed_t[i], passed_t[last_idx]);
          std::swap(step[i], step[last_idx]);
        }
        active_item_idx.pop_back();
        evidence.pop_back();
        passed_t.pop_back();
        step.pop_back();
        break;
      }
    }
  }

  return List::create(
    Named("item_idx") = IntegerVector(reached_item_idx.begin(), reached_item_idx.end()),
    Named("rt") = NumericVector(rt.begin(), rt.end()),
    Named("evidence") = NumericVector(reached_evidence.begin(), reached_evidence.end())
  );
}
