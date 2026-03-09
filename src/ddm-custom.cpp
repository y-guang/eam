#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

//' Simulate evidence accumulation for a custom alternating-noise drift-diffusion model
//' 
//' This is a custom implementation where noise direction alternates at each step.
//' The noise is taken as absolute value and then multiplied by a sign that flips
//' at each time step, creating an "advance-retreat" pattern.
//' 
//' @param n_items Number of items to simulate
//' @param threshold Decision threshold (A parameter)
//' @param drift Drift rate (V parameter) - can be a vector for each item
//' @param starting_point Starting evidence (Z parameter) - can be a vector for each item
//' @param ndt Non-decision time - can be a vector for each item
//' @param max_t Maximum time allowed for accumulation
//' @param dt Time step size
//' @param max_reached Maximum number of items to recall
//' @param noise_func Function to generate noise values
//' 
//' @return A list with item_idx (indices of items that reached threshold) 
//'         and rt (reaction times)
//' 
//' @keywords internal
//' @export
// [[Rcpp::export]]
List accumulate_evidence_ddm_custom(
  int n_items,
  double threshold,
  NumericVector drift,
  NumericVector starting_point,
  NumericVector ndt,
  double max_t,
  double dt,
  int max_reached,
  Function noise_func
) {
  // Input validation
  if (n_items <= 0) {
    stop("n_items must be > 0");
  }
  if (threshold <= 0) {
    stop("threshold must be > 0");
  }
  if (dt <= 0 || max_t <= 0) {
    stop("dt and max_t must be > 0");
  }
  if (max_reached <= 0) {
    stop("max_reached must be > 0");
  }
  if (drift.size() != n_items) {
    stop("Length of drift must be equal to n_items");
  }
  if (starting_point.size() != n_items) {
    stop("Length of starting_point must be equal to n_items");
  }
  if (ndt.size() != n_items) {
    stop("Length of ndt must be equal to n_items");
  }
  
  // Initialize vectors for tracking each item
  std::vector<double> evidence(starting_point.begin(), starting_point.end());
  std::vector<double> time_passed(ndt.begin(), ndt.end());
  std::vector<bool> is_active(n_items, true);
  std::vector<int> sign(n_items, 1);  // Track alternating sign for each item
  
  // Result vectors
  std::vector<int> reached_item_idx;
  std::vector<double> reaction_times;
  
  int n_recalled = 0;
  int n_active = n_items;
  
  // Main simulation loop
  while (n_active > 0 && n_recalled < max_reached) {
    // Generate noise for all active items
    NumericVector noise = as<NumericVector>(noise_func(n_items, dt));
    
    // Update each item
    for (int i = 0; i < n_items; i++) {
      if (!is_active[i]) {
        continue;
      }
      
      // Check if item has passed non-decision time
      if (time_passed[i] >= ndt[i]) {
        // Core accumulation logic with alternating noise:
        // 1. Take absolute value of noise
        double abs_noise = std::abs(noise[i]);
        // 2. Apply sign (alternates each step)
        double signed_noise = abs_noise * sign[i];
        // 3. Accumulate: evidence = evidence + drift * dt + signed_noise
        evidence[i] = evidence[i] + drift[i] * dt + signed_noise;
        
        // 4. Flip sign for next step
        sign[i] = -sign[i];
        
        // Check if threshold is reached
        if (std::abs(evidence[i]) >= threshold) {
          reached_item_idx.push_back(i + 1); // R uses 1-based indexing
          reaction_times.push_back(time_passed[i]);
          is_active[i] = false;
          n_recalled++;
          n_active--;
          break; // Only one item can be recalled per time step
        }
      }
      
      // Update time
      time_passed[i] += dt;
      
      // Check timeout
      if (time_passed[i] >= max_t) {
        is_active[i] = false;
        n_active--;
      }
    }
  }
  
  // Return results
  if (n_recalled > 0) {
    return List::create(
      Named("item_idx") = IntegerVector(reached_item_idx.begin(), reached_item_idx.end()),
      Named("rt") = NumericVector(reaction_times.begin(), reaction_times.end())
    );
  } else {
    return List::create(
      Named("item_idx") = IntegerVector(0),
      Named("rt") = NumericVector(0)
    );
  }
}
