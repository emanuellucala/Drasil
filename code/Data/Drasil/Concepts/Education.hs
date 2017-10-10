module Data.Drasil.Concepts.Education where

import Language.Drasil
import Data.Drasil.Concepts.Documentation
import Data.Drasil.Concepts.PhysicalProperties

calculus, civil, degree_, engineering, structural, mechanics,
  undergraduate, highSchool, physical_, chemistry :: NamedChunk

calculus        = npnc "calculus"       (cn   "calculus"     )
civil           = npnc "civil"          (cn'  "civil"        )--FIXME: Adjective
degree_         = npnc "degree"         (cn'  "degree"       )
engineering     = npnc "engineering"    (cn'  "engineering"  )
mechanics       = npnc "mechanics"      (cn   "mechanics"    )
structural      = npnc "structural"     (cn'  "structural"   )--FIXME: Adjective
undergraduate   = npnc "undergraduate"  (cn'  "undergraduate")
highSchool      = npnc "highSchool"     (cn'  "high school"  )
chemistry       = npnc "chemistry"      (cn'  "chemistry"    )
physical_       = npnc "physical"       (cn'  "physical"     )--FIXME: Adjective

undergradDegree, scndYrCalculus, solidMechanics, secondYear, structuralEng,
  structuralMechanics, civilEng, highSchoolCalculus, highSchoolPhysics,
  frstYr, physChem :: NamedChunk

civilEng                     = compoundNC civil engineering
physChem                     = compoundNC physical_ chemistry
highSchoolCalculus           = compoundNC highSchool calculus
highSchoolPhysics            = compoundNC highSchool physics
scndYrCalculus               = compoundNC secondYear calculus
frstYr                       = compoundNC first year
secondYear                   = compoundNC second_ year
solidMechanics               = compoundNC solid mechanics
structuralEng                = compoundNC structural engineering
structuralMechanics          = compoundNC structural mechanics
undergradDegree              = compoundNC undergraduate degree_
