\begin{code}
module Parallel where

open import Level
open import Function
open import Atom
open import Alpha
open import ListProperties
open import Term hiding (fv)
open import TermRecursion
open import TermInduction
open import TermAcc
open import NaturalProperties
open import Equivariant
open import Permutation
open import Substitution

open import Data.Bool hiding (_∨_)
open import Data.Nat hiding (_*_)
open import Data.Nat.Properties
open import Data.Empty
open import Data.Sum -- renaming (_⊎_ to _∨_)
open import Data.List
open import Data.List.Any as Any hiding (map)
open import Data.List.Any.Membership
open Any.Membership-≡
open import Data.Product
open import Relation.Binary.PropositionalEquality as PropEq renaming ([_] to [_]ᵢ)
open import Relation.Nullary
open import Relation.Nullary.Decidable
\end{code}

Parallel reduction.

\begin{code}
⇉hv : Atom → Λ → Set
⇉hv a M = v a ≡ M
\end{code}

\begin{code}
⇉h· : (Λ → Set) → (Λ → Set) → Λ → Λ → Λ → Set
⇉h· r1 r2 (ƛ x M)   N P         =  ∃ (λ P' → ∃ (λ P'' → P ≡ P' · P''         × r1 P'        × r2 P'')) ⊎ 
                                   ∃ (λ P' → ∃ (λ P'' → ∃ (λ y → P ∼α P' [ y ≔ P'' ]  × r1 (ƛ y P')  × r2 P''))) 
⇉h· r1 r2 (M · M')  N (P ·  P') =  r1 P × r2 P'
⇉h· r1 r2 (_ · _)   N (v _)     =  ⊥ 
⇉h· r1 r2 (_ · _)   N (ƛ _ _)   =  ⊥ 
⇉h· r1 r2 (v x)     N (P ·  P') =  r1 P × r2 P'
⇉h· r1 r2 (v _)     N (v _)     =  ⊥ 
⇉h· r1 r2 (v _)     N (ƛ _ _)   =  ⊥ 
\end{code}

\begin{code}
⇉hƛ : Atom → (Λ → Set) → Λ → Λ → Set
⇉hƛ _ r _ (v _)    = ⊥ 
⇉hƛ _ _ _ (_ · _)  = ⊥
⇉hƛ a r _ (ƛ b M)  = r (（ b ∙ a ） M)
\end{code}

\begin{code}
--infix 4 _⇉_
⇉[] : List Atom → Λ → Λ → Set
⇉[] xs = ΛRec (Λ → Set) ⇉hv ⇉h· (xs , ⇉hƛ)

infix 4 _⇉_
_⇉_ : Λ → Λ → Set
M ⇉ N = ∃ (λ xs → ⇉[] xs M N)
\end{code}

Is $\alpha$-compatible in the left side of the relation by being defined with $\alpha$ recursion principle.

\begin{code}
lemma⇉αleft : {M N P : Λ} → M ∼α N → N ⇉ P → M ⇉ P
lemma⇉αleft {M} {N} {P} M∼N (xs , N⇉P) 
  = xs , subst (λ f → f P) (sym (lemmaΛRecStrongαCompatible (Λ → Set) ⇉hv ⇉h· (xs , ⇉hƛ) M N M∼N)) N⇉P
\end{code}

\begin{code}
lemma⇉Equiv : (xs : List Atom) → EquivariantRel (⇉[] xs)
lemma⇉Equiv xs {v x}           .{v x}       π refl 
  rewrite lemmaπv {x} {π} = refl
lemma⇉Equiv xs {ƛ x M · N}     .{P' · P''}  π (inj₁ (P' , P'' , refl , ƛxM⇉P' , N⇉P'')) 
  with lemma⇉Equiv xs {ƛ x M} {P'} π ƛxM⇉P'
... | hiƛxM⇉P'
  rewrite  lemmaπ· {ƛ x M}  {N}   {π} 
  |        lemmaπ· {P'}     {P''} {π} 
  |        lemmaπƛ {x}      {M}   {π}
  =  inj₁ ( (π ∙ P') ,  (π ∙ P'') , refl , hiƛxM⇉P' , lemma⇉Equiv xs π N⇉P'' )
lemma⇉Equiv xs {ƛ x M · N}     {P}          π (inj₂ (P' , P'' , y , P∼P'[y≔P''] , ƛxM⇉ƛyP' , N⇉P'')) 
  with lemma⇉Equiv xs {ƛ x M} {ƛ y P'} π ƛxM⇉ƛyP'
... | hiƛxM⇉ƛyP'
  rewrite  lemmaπ· {ƛ x M}  {N}   {π} 
  |        lemmaπ· {P'}     {P''} {π} 
  |        lemmaπƛ {x}      {M}   {π}
  |        lemmaπƛ {y}      {P'}  {π}
  = inj₂ ( (π ∙ P') ,  (π ∙ P'') , π ∙ₐ y , {!!} ,  hiƛxM⇉ƛyP' ,  lemma⇉Equiv xs π N⇉P'')
lemma⇉Equiv xs {(M · M') · N}  {P · P'}     π MM'⇉[xs]N
  = {!!}
lemma⇉Equiv xs {(_ · _) · _}   {v _}        _ ()
lemma⇉Equiv xs {(_ · _) · _}   {ƛ _ _}      _ ()
lemma⇉Equiv xs {v x · N}       {P · P'}     π MM'⇉[xs]N
  = {!!}
lemma⇉Equiv xs {v _ · N}       {v _}        _ ()
lemma⇉Equiv xs {v _ · N}       {ƛ _ _}      _ ()
lemma⇉Equiv xs {ƛ x M}         {v _}        _ ()
lemma⇉Equiv xs {ƛ x M}         {_ · _}      _ ()
lemma⇉Equiv xs {ƛ x M}         {ƛ y N}      π （xχ）⇉[xs]（yχ）N -- esta no sale ?????
  = {!!}
\end{code}

Puedo demostrar que xs ⊆ ys → ⇉[] xs M N → ⇉[] ys M N ??



-- \begin{code}
-- lemma⇉αleft : {M N P : Λ} → M ∼α N → N ⇉ P → M ⇉ P
-- lemma⇉αleft {M} {N} {P} M∼N N⇉P 
--   rewrite lemmaΛRecStrongαCompatible (Λ → Set) ⇉hv ⇉h· ([] , ⇉hƛ) M N M∼N = N⇉P
-- \end{code}

-- \begin{code}
-- lemma⇉Equiv#Left : {a b : Atom}{M N : Λ} → a # M → b # M → M ⇉ N → （ a ∙ b ） M ⇉ N
-- lemma⇉Equiv#Left {a} {b} {M} a#M b#M M⇉N 
--   rewrite lemmaΛRecEquiv# (Λ → Set) ⇉hv ⇉h· ([] , ⇉hƛ) M a b a#M b#M 
--   = M⇉N 
-- \end{code}

-- \begin{code}
-- lemma⇉·c :  {M M' N N' : Λ} → M ⇉ N → M' ⇉ N' → M · M' ⇉ N · N'
-- lemma⇉·c {v x}                  M⇉N M'⇉N' 
--   = M⇉N , M'⇉N'
-- lemma⇉·c {M · P}                M⇉N M'⇉N' 
--   = M⇉N , M'⇉N'
-- lemma⇉·c {ƛ x M} {M'} {N} {N'}  M⇉N M'⇉N' 
--   = inj₁ (N , N' , refl ,  M⇉N , M'⇉N')
-- \end{code}

-- Examples

-- \begin{code}
-- test0 : ƛ 3 (v 1) ⇉ ƛ 2 (v 1)
-- test0 = refl

-- test1 : (ƛ 2 (v 2)) · (v 3) ⇉ (ƛ 2 (v 2)) · (v 3)
-- test1 =  inj₁ ((ƛ 2 (v 2)) , v 3 , refl , refl , refl)

-- test2 : (ƛ 2 (v 2)) · (v 3) ⇉ v 3 
-- test2 = inj₂ (v 0 ,  v 3 , ℕ.zero , ∼αv , refl , refl)
-- \end{code}

-- Also the right side of the relation is $\alpha$-compatible  !

-- How easy is prove something about this relation ? next is induction on M or on the relation ?

-- \begin{code}
-- lemma⇉# : {a : Atom}{M N : Λ} → M ⇉ N → a # M → a # N
-- lemma⇉# = {!!}
-- --
-- -- use the alpha induction principle ?
-- P⇉αright : {N P : Λ} → N ∼α P → Λ → Set
-- P⇉αright {N} {P} N∼P M = M ⇉ N → M ⇉ P
-- --
-- lemma⇉αright' : {M N P : Λ}(N∼P : N ∼α P) → P⇉αright {N} {P} N∼P M
-- lemma⇉αright' {M} {N} {P} N∼P M⇉N
--   = TermαPrimInd  (P⇉αright {N} {P} N∼P)
--                   {!!} --(λ {M} {M'} M∼M' P⇉αrightM {N} {P} M'⇉N N∼P → lemma⇉αleft (σ M∼M') (P⇉αrightM {N} {P} (lemma⇉αleft M∼M' M'⇉N) N∼P)   ) 
--                   {!!} --lemma⇉rightv 
--                   {!!} --lemma⇉right· 
--                   {!!}
--                   M M⇉N 
--   where
--   -- lemma⇉rightv :  (a : ℕ) {N P : Λ} → v a ⇉ N → N ∼α P → v a ⇉ P
--   -- lemma⇉rightv a .{v a} .{v a} refl ∼αv = refl
--   -- lemma⇉right· :  (M M' : Λ) 
--   --                 → ({N P : Λ} → M  ⇉ N → N ∼α P → M  ⇉ P) 
--   --                 → ({N P : Λ} → M' ⇉ N → N ∼α P → M' ⇉ P) 
--   --                 → {N P : Λ}  → M · M' ⇉ N → N ∼α P → M · M' ⇉ P
--   -- lemma⇉right·  (_ · _)   _    _   _     {v _}       () _
--   -- lemma⇉right·  (_ · _)   _    _   _     {ƛ _ _}     () _
--   -- lemma⇉right·  (v _)     _    _   _     {v _}       () _
--   -- lemma⇉right·  (v _)     _    _   _     {ƛ _ _}     () _
--   -- lemma⇉right·  (ƛ a M)   M'   hiM hiM'  .{N · N'}  .{P · P'} 
--   --               (inj₁ (N , N' , refl , ƛaM⇉N , M'⇉N')) 
--   --               (∼α· .{N} {P} .{N'} {P'} N∼P N'∼P') 
--   --   = inj₁ (P , P' , refl , hiM {N} {P} ƛaM⇉N N∼P , hiM' {N'} {P'} M'⇉N' N'∼P')
--   -- lemma⇉right·  (ƛ a M)   M'   hiM hiM'  {N}         {P}
--   --               (inj₂ (N' , N'' , y ,  N∼N'[a≔N''] , ƛaM⇉ƛaN' , M'⇉N'' )) 
--   --               N∼P 
--   --   = inj₂ (N' , N'' ,  y ,  τ (σ N∼P) (N∼N'[a≔N'']) ,  ƛaM⇉ƛaN' , M'⇉N'') -- τ (σ N∼P) (N∼N'[a≔N''])  , ƛaM⇉ƛaN'
--   -- lemma⇉right·  (M · M')  M''  hiM hiM'  {N · N'}  {P · P'}
--   --               (MM'⇉N , M''⇉N') 
--   --               (∼α· N∼P N'∼P') 
--   --   = hiM {N} {P} MM'⇉N N∼P , hiM' {N'} {P'} M''⇉N' N'∼P'
--   -- lemma⇉right·  (v x)     M'   hiM hiM'  {N · N'}  .{P · P'}
--   --               (x⇉N , M'⇉N') 
--   --               (∼α· .{N} {P} .{N'} {P'}  N∼P N'∼P') 
--   --   = hiM {N} {P} x⇉N N∼P , hiM' {N'} {P'} M'⇉N' N'∼P'
--   lemma⇉rightƛ  :  (M : Λ) (a : ℕ) 
--                    → a ∉ []
--                    → (M ⇉ N → M ⇉ P)
--                    → ƛ a M ⇉ N  
--                    → ƛ a M ⇉ P
--   lemma⇉rightƛ  _ _ _ _  {v _}          () _ 
--   lemma⇉rightƛ  _ _ _ _  {_ · _}        () _ 
--   lemma⇉rightƛ  M a a∉[] hi  {ƛ b N} .{ƛ c P}
--                 （aχ）M⇉（bχ）N
--                 (∼αƛ .{N} {P} .{b} {c} xs ∀e→e∉xs→（be）N∼（ce）P)
--     = {!!}
-- --
-- lemma⇉αright : {M N P : Λ} →  M ⇉ N → N ∼α P → M ⇉ P
-- lemma⇉αright {M} {N} {P} M⇉N N∼P 
--   = TermIndPerm  (λ M → (N P : Λ) → M ⇉ N → N ∼α P → M ⇉ P) 
--                  lemma⇉rightv lemma⇉right· lemma⇉rightƛ 
--                  M N P M⇉N N∼P
--   where 
--   lemma⇉rightv :  (a : ℕ) (N P : Λ) → v a ⇉ N → N ∼α P → v a ⇉ P
--   lemma⇉rightv a .(v a) .(v a) refl ∼αv = refl
--   lemma⇉right· :  (M M' : Λ) 
--                   → ((N P : Λ) → M  ⇉ N → N ∼α P → M  ⇉ P) 
--                   → ((N P : Λ) → M' ⇉ N → N ∼α P → M' ⇉ P) 
--                   → (N P : Λ) → M · M' ⇉ N → N ∼α P → M · M' ⇉ P
--   lemma⇉right·  (_ · _)   _    _   _     (v _)      _ () _
--   lemma⇉right·  (_ · _)   _    _   _     (ƛ _ _)    _ () _
--   lemma⇉right·  (v _)     _    _   _     (v _)      _ () _
--   lemma⇉right·  (v _)     _    _   _     (ƛ _ _)    _ () _
--   lemma⇉right·  (ƛ a M)   M'   hiM hiM'  .(N · N')  .(P · P') 
--                 (inj₁ (N , N' , refl , ƛaM⇉N , M'⇉N')) 
--                 (∼α· .{N} {P} .{N'} {P'} N∼P N'∼P') 
--     = inj₁ (P , P' , refl , hiM N P ƛaM⇉N N∼P , hiM' N' P' M'⇉N' N'∼P')
--   lemma⇉right·  (ƛ a M)   M'   hiM hiM'  N          P
--                 (inj₂ (N' , N'' , y ,  N∼N'[a≔N''] , ƛaM⇉ƛaN' , M'⇉N'' )) 
--                 N∼P 
--     = inj₂ (N' , N'' ,  y ,  τ (σ N∼P) (N∼N'[a≔N'']) ,  ƛaM⇉ƛaN' , M'⇉N'') -- τ (σ N∼P) (N∼N'[a≔N''])  , ƛaM⇉ƛaN'
--   lemma⇉right·  (M · M')  M''  hiM hiM'  (N · N')  (P · P')
--                 (MM'⇉N , M''⇉N') 
--                 (∼α· N∼P N'∼P') 
--     = hiM N P MM'⇉N N∼P , hiM' N' P' M''⇉N' N'∼P'
--   lemma⇉right·  (v x)     M'   hiM hiM'  (N · N')  .(P · P')
--                 (x⇉N , M'⇉N') 
--                 (∼α· .{N} {P} .{N'} {P'}  N∼P N'∼P') 
--     = hiM N P x⇉N N∼P , hiM' N' P' M'⇉N' N'∼P'
--   lemma⇉rightƛ  :  (M : Λ) (a : ℕ)
--                    → ((π : List (Atom × Atom)) (N P : Λ) → (π ∙ M) ⇉ N → N ∼α P → (π ∙ M) ⇉ P)
--                    → (N P : Λ) → ƛ a M ⇉ N → N ∼α P → ƛ a M ⇉ P
--   lemma⇉rightƛ  _ _ _   (v _  )  _       () _ 
--   lemma⇉rightƛ  _ _ _   (_ · _)  _       () _ 
--   lemma⇉rightƛ  M a hi  (ƛ b N) .(ƛ c P)
--                 （ad）M⇉（bd）N
--                 (∼αƛ .{N} {P} .{b} {c} xs ∀e→e∉xs→（be）N∼（ce）P)
--     with lemma⇉# {d} {ƛ a M} {ƛ b N} （ad）M⇉（bd）N d#ƛaM
--     where
--     d = χ [] (ƛ a M)
--     d#ƛaM = χ# [] (ƛ a M)
--   ... | d#ƛbN 
--     rewrite aux ((Λ → Set) × Λ) < ⇉hv , v > (app ⇉h·) [] (abs ⇉hƛ) M [ (a , χ [] (ƛ a M)) ]
--     = hi [ ( a , d ) ] (（ b ∙ d ） N) (（ c ∙ d ） P) （ad）M⇉（bd）N bdN∼cdP
--     where
--     d = χ [] (ƛ a M)
--     d#ƛaM = χ# [] (ƛ a M)
--     d#ƛcP = lemma∼α# (∼αƛ {N} {P} {b} {c} xs ∀e→e∉xs→（be）N∼（ce）P) d#ƛbN
--     x = χ xs (ƛ b N · ƛ c P)
--     x#ƛbN : x # ƛ b N
--     x#ƛbN with χ# xs (ƛ b N · ƛ c P)
--     ... | #· x#ƛbN _ = x#ƛbN
--     x#ƛcP : x # ƛ c P
--     x#ƛcP with χ# xs (ƛ b N · ƛ c P)
--     ... | #· _ x#ƛcP = x#ƛcP
--     x∉xs = χ∉ xs (ƛ b N · ƛ c P)
--     bdN∼cdP : （ b ∙ d ） N ∼α （ c ∙ d ） P
--     bdN∼cdP =  begin
--                  （ b ∙ d ） N
--                ∼⟨ σ (lemma∙cancel∼α'' d#ƛbN x#ƛbN) ⟩
--                  （ x ∙ d ） （ b ∙ x ） N
--                ∼⟨ lemma∼αEquiv [ (x , d) ] (∀e→e∉xs→（be）N∼（ce）P x x∉xs)  ⟩
--                  （ x ∙ d ） （ c ∙ x ） P
--                ∼⟨ lemma∙cancel∼α'' d#ƛcP x#ƛcP ⟩
--                  （ c ∙ d ） P
--                ∎
-- \end{code}

-- \begin{code}
-- lemma⇉Equiv#Right : {a b : Atom}{M N : Λ} → a # N → b # N → M ⇉ N → M ⇉ （ a ∙ b ） N
-- lemma⇉Equiv#Right {a} {b} {M} {N} a#N b#N M⇉N = lemma⇉αright {M} {N} {（ a ∙ b ） N} M⇉N (lemma#∼α a#N b#N)
-- \end{code}

-- \begin{code}
-- lemma⇉Equiv' :  (a b : Atom){M N : Λ} → a # M → b # M → M ⇉ N → （ a ∙ b ） M ⇉ （ a ∙ b ） N
-- lemma⇉Equiv' a b {M} {N} a#M b#M M⇉N = lemma⇉Equiv#Left a#M b#M (lemma⇉Equiv#Right {M = M} {N} (lemma⇉# M⇉N a#M) (lemma⇉# M⇉N b#M) M⇉N)
-- \end{code}

-- \begin{code}
-- lemma⇉Equiv :  (a b : Atom){M N : Λ} → M ⇉ N → （ a ∙ b ） M ⇉ （ a ∙ b ） N
-- lemma⇉Equiv a b {v x}                        refl     = refl
-- lemma⇉Equiv a b {v x       · M'}  {v _}      ()
-- lemma⇉Equiv a b {v x       · M'}  {ƛ _ _}    ()
-- lemma⇉Equiv a b {v x       · M'}  {N · N'}   (x⇉N , M'⇉N') 
--   = lemma⇉Equiv a b {v x} {N} x⇉N , lemma⇉Equiv a b {M'} {N'} M'⇉N'
-- lemma⇉Equiv a b {(M · M') · M''}  {v _}      ()
-- lemma⇉Equiv a b {(M · M') · M''}  {ƛ _ _}    ()
-- lemma⇉Equiv a b {(M · M') · M''}  {N · N'}   (MM'⇉N , M''⇉N')
--   = lemma⇉Equiv a b {M · M'} {N} MM'⇉N , lemma⇉Equiv a b {M''} {N'} M''⇉N'
-- lemma⇉Equiv a b {ƛ x M · M'}      .{P · P'}  (inj₁ (P , P' , refl , ƛxM⇉P , M'⇉P')) 
--   = inj₁ (（ a ∙ b ） P , （ a ∙ b ） P' , refl , lemma⇉Equiv a b {ƛ x M} {P} ƛxM⇉P , lemma⇉Equiv a b {M'} {P'} M'⇉P')
-- lemma⇉Equiv a b {ƛ x M · M'}                 (inj₂ (P , P' , y , N∼P[y=P'] , ƛxM⇉ƛyP , M'⇉P')) 
--   =  inj₂ (（ a ∙ b ） P , （ a ∙ b ） P' , （ a ∙ b ）ₐ y , {! lemmaSw[] a b y P'!} , lemma⇉Equiv a b {ƛ x M} {ƛ y P} ƛxM⇉ƛyP , lemma⇉Equiv a b {M'} {P'} M'⇉P')
-- lemma⇉Equiv a b {ƛ x M}            {v _}     ()
-- lemma⇉Equiv a b {ƛ x M}            {_ · _}   ()
-- lemma⇉Equiv a b {ƛ x M}            {ƛ y N}   （xχ）M⇉（yχ）N 
--   = {!!}
-- \end{code}

-- \begin{code}
-- lemma⇉ƛc : {x : Atom}{M N : Λ} → M ⇉ N → ƛ x M ⇉ ƛ x N
-- lemma⇉ƛc {x} {M} {N} M⇉N 
--   rewrite (aux ((Λ → Set) × Λ) < ⇉hv , v > (app ⇉h·) [] (abs ⇉hƛ) M [( x , (χ [] (ƛ x M)))]) 
--   = lemma⇉Equiv x (χ [] (ƛ x M)) {M} {N} M⇉N
-- --
-- lemma⇉ƛd :  {x : Atom}{M N : Λ} → ƛ x M ⇉ N → ∃ (λ P → N ∼α ƛ x P × M ⇉ P)
-- lemma⇉ƛd          {N = v _}    ()
-- lemma⇉ƛd          {N = _ · _}  ()
-- lemma⇉ƛd {x} {M}  {ƛ y N}      ƛxM⇉ƛyN
--   =  （ y ∙ x ） N ,  lemma∼αλ' x#ƛyN , M⇉（yx）N
--   where
--   z = χ [] (ƛ x M)
--   z#ƛxM = χ# [] (ƛ x M)
--   z#ƛyN : z # ƛ y N
--   z#ƛyN = lemma⇉# ƛxM⇉ƛyN z#ƛxM
--   x#ƛxM : x # ƛ x M
--   x#ƛxM = #ƛ≡
--   x#ƛyN : x # ƛ y N
--   x#ƛyN = lemma⇉# ƛxM⇉ƛyN x#ƛxM
--   （xz）M⇉（yz）N : （ x ∙ z ） M ⇉ （ y ∙ z ） N
--   （xz）M⇉（yz）N rewrite sym (aux ((Λ → Set) × Λ) < ⇉hv , v > (app ⇉h·) [] (abs ⇉hƛ) M [( x , z)]) 
--     = ƛxM⇉ƛyN   
--   （xz）（yz）N∼（yx）N : （ x ∙ z ） （ y ∙ z ） N ∼α （ y ∙ x ） N
--   （xz）（yz）N∼（yx）N =  begin
--                            （ x ∙ z ） （ y ∙ z ） N
--                          ≈⟨ lemma∙comm ⟩
--                            （ z ∙ x ） （ y ∙ z ） N
--                          ∼⟨  lemma∙cancel∼α'' x#ƛyN z#ƛyN ⟩
--                            （ y ∙ x ） N
--                          ∎                         
--   M⇉（yx）N : M ⇉ （ y ∙ x ） N
--   M⇉（yx）N  =  subst (λ p → p ⇉ （ y ∙ x ） N)
--                      (lemma（ab）（ab）M≡M {x} {z} {M})
--                      (lemma⇉αright  {（ x ∙ z ） （ x ∙ z ） M} 
--                                     (lemma⇉Equiv x z {（ x ∙ z ） M} {（ y ∙ z ） N} （xz）M⇉（yz）N) 
--                                     （xz）（yz）N∼（yx）N)  
-- \end{code}


-- Substitution lemma for parallel reduction.

-- \begin{code}
-- lemma⇉subst : {a : Atom}{M N P Q : Λ} → M ⇉ N → P ⇉ Q → M [ a ≔ P ] ⇉ N [ a ≔ Q ]
-- lemma⇉subst = {!!}
-- \end{code}

-- \begin{code}
-- test3 : (ƛ 2 (v 2)) · (ƛ 0 (v 0)) ⇉ (ƛ 5 (v 5))
-- test3 = inj₂ (v 0 , (ƛ 0 (v 0)) , ℕ.zero , ∼αƛ [] (λ c _ → ∼αv) , refl , refl)
-- \end{code}

-- \begin{code}
-- diam⇉ :  {M N P : Λ} → M ⇉ N → M ⇉ P
--          → ∃ (λ Q → N ⇉ Q × P ⇉ Q)
-- diam⇉  {v a}             .{v a}     .{v a} 
--        refl 
--        refl 
--   = v a , refl , refl
-- diam⇉  {ƛ x M · M'}      .{N · N'}   .{P · P'}
--        (inj₁ (N , N' , refl , ƛxM⇉N , M'⇉N'))
--        (inj₁ (P , P' , refl , ƛxM⇉P , M'⇉P')) 
--   with  diam⇉ {ƛ x M} {N} {P} ƛxM⇉N ƛxM⇉P 
--      |  diam⇉ {M'} {N'} {P'} M'⇉N' M'⇉P'
-- ...  |  Q , N⇉Q , P⇉Q | Q' , N'⇉Q' , P'⇉Q'
--   = Q · Q' , lemma⇉· {N} {N'} N⇉Q N'⇉Q' , lemma⇉· {P} {P'} P⇉Q P'⇉Q' 
-- diam⇉  {ƛ x M · M'}      .{v _ · N'}   {P}
--        (inj₁ (v _ , N' , refl , () , M'⇉N'))
--        (inj₂ (P' , P'' , P∼P'[x≔P''] , ƛxM⇉ƛχP' , M'⇉P''))
-- diam⇉  {ƛ x M · M'}      .{(_ · _) · N'}   {P}
--        (inj₁ (_ · _ , N' , refl , () , M'⇉N'))
--        (inj₂ (P' , P'' , P∼P'[x≔P''] , ƛxM⇉ƛχP' , M'⇉P''))
-- diam⇉  {ƛ x M · M'}      .{ƛ y N · N'}   {P}
--        (inj₁ (ƛ y N , N' , refl , ƛxM⇉ƛyN , M'⇉N'))
--        (inj₂ (P' , P'' , P∼P'[x≔P''] , ƛxM⇉ƛχP' , M'⇉P''))
--   with  diam⇉ {ƛ x M} {ƛ y N} {ƛ (χ [] (ƛ x M)) P'} ƛxM⇉ƛyN ƛxM⇉ƛχP' 
--      |  diam⇉ {M'} {N'} {P''} M'⇉N' M'⇉P''
-- ...  |  Q , ƛyN⇉Q , ƛχP'⇉Q | Q' , N'⇉Q' , P''⇉Q'
--   = Q [ x ≔ Q' ] , {! !} , {!!}
-- diam⇉  {ƛ x M · M'}      {N} 
--        (inj₂ (N' , N'' , N∼N'[x≔N''] , M⇉N' , M'⇉N''))
--        M⇉P 
--   = {!!}
-- diam⇉  {(M · M')  · M''}  {N · N'}   M⇉N M⇉P = {!!}
-- diam⇉  {(_ · _)   · _}    {v _}      () _
-- diam⇉  {(_ · _)   · _}    {ƛ _ _}    () _
-- diam⇉  {v x · M}          {N · N'}   M⇉N M⇉P = {!!}
-- diam⇉  {v _       · _ }   {v _}      () _
-- diam⇉  {v _       · _ }   {ƛ _ _}    () _
-- diam⇉  {ƛ x M}            M⇉N M⇉P = {!!}
-- \end{code}


