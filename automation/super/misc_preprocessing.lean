import .clause .prover_state
open expr list monad

namespace super

meta def is_taut (c : clause) : tactic bool := do
qf ← clause.open_constn c c↣num_quants,
return $ list.bor (do
  l1 ← clause.get_lits qf.1, guard $ clause.literal.is_neg l1,
  l2 ← clause.get_lits qf.1, guard $ clause.literal.is_pos l2,
  [decidable.to_bool (clause.literal.formula l1 = clause.literal.formula l2)])

open tactic
example (i : Type) (p : i → i → Type) (c : i) (h : ∀ (x : i), p x c → p x c) : true := by do
h ← get_local `h, hcls ← clause.of_classical_proof h,
taut ← is_taut hcls,
when (¬taut) failed,
to_expr `(trivial) >>= apply

meta def tautology_removal_pre : prover unit :=
preprocessing_rule $ λnew, filterM (λc, liftM bnot $♯ is_taut c↣c) new

meta def remove_duplicates : list derived_clause → list derived_clause
| [] := []
| (c :: cs) :=
  let (same_type, other_type) := partition (λc' : derived_clause, c'↣c↣type = c↣c↣type) cs in
  { c with sc := foldl score.min c↣sc (same_type↣for $ λc, c↣sc) } :: remove_duplicates other_type

meta def remove_duplicates_pre : prover unit :=
preprocessing_rule $ λnew,
return $ remove_duplicates new

end super
