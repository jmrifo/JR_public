; CLIMATE CLUB SIMULATION
extensions [palette rnd]



turtles-own[wealth  migrated emergency_migrated growth_modifier]
patches-own[damage propensity pop_part LOCALemission
  dead development economy  emission_damage_modifier]

globals[mean_values second_mean_values
  mean-values
  median-value
  meadian_wealth
  welfare
  emission_calibration
  local_damage_calibration
]


to setup
  clear-all
  reset-ticks

  ;calibrate factors for emissions (for balancing)
  set emission_calibration 10000
  set local_damage_calibration 0.001


;setup patches
  ask patches[
    set pcolor red
    set dead 0

;    let a random-normal 1 15
;    ifelse a > 1[if a < 100 [set damage a]][set damage 1];this basically results
    ;in the right half of a normal dist, comfigures baseline damage
    set pop_part random-float 1 ;to determine population,
    ;patches draw a random float which will be used as population weights
    set development random-normal 1 1 ;to determine state of economy, and climate
    ;patches draw random float which will be used as a multiplier for the population
    if development < 0.1 [set development 0.1] ; to have development as a multiplier, it
    ; needs to be greater than 1

;set saturation
    palette:set-saturation damage

;generate the emission damage modifier
    set emission_damage_modifier random-normal 1 2
    if emission_damage_modifier < 0.1 [set emission_damage_modifier 0.1]
    set emission_damage_modifier 0.5 * emission_damage_modifier

; population is called from the reporter
    sprout population

  ]

;setup wealth and growth_modifer of turtles
  ask turtles[
    set wealth base_wealth_reporter
    set size wealth / 50
    set growth_modifier random-normal 0.1 0.01

    ;histogram [wealth] of turtles
  ]
;Setup patch economy
  ask patches[
    set economy economy_reporter
  ]
;histogram [economy] of patches



; Initialize mean-values as an empty list (for plotting)
      set mean_values []
  set second_mean_values []

end

;------------------------------------
;function to check values before running, otherwise not relavant to the program
;------------------------------------
to check_vals
  let mean_damge mean [damage] of patches
  let mean_damage_mod mean [emission_damage_modifier] of patches
  let mean_pop mean [population] of patches
  let mean_development mean [development] of patches

  show "mean_damge"
  show mean_damge
  show "mean_damage_mod"
  show mean_damage_mod
  show "mean_pop"
  show mean_pop
  show "mean_development"
  show mean_development
  show "-----"
  let mean_wealth_1 mean [wealth] of turtles
  show "mean wealth"
  show mean_wealth_1
    let median_wealth median [wealth] of turtles
  show "median wealth"
  show median_wealth
end


;------------------------------------
;------------------------------------
;------------------------------------

to go
  let maxTicks 2000  ; Set a maximum number of ticks to avoid infinite loop

  loop [
    if ticks = maxTicks [stop]



;this updates the turtles' wealth depending on development and sets their size scaled accordingly
    ask turtles [
      if wealth > 0[
        set wealth wealth + (patch_development_reporter * growth_modifier)
    let s wealth / 50
      ifelse s < 3[set size s][set size 3]
    ]
    ]

;generates expectations and depending on these migrates (series of reporters)
    migrate


; displaces (reporter)
    emergency_migrate



;refresh economy and local emissions (these are later in the description, but called here earllier, since calculation timing does not matter
    ask patches[set economy economy_reporter
    set LOCALemission local_emission_reporter
    ]

    ; this "kills" turtles on dead patches
    ask patches[
          if development <= 0[ ;if the patch is dead
        ask turtles-here[
          set wealth 0
          set shape "face sad"
          set size 0
      ]]


      ;this is just for color saturation adjustment
      ifelse development > 1
      [set damage 0][ifelse development > 0[ set damage (1 - development) * 100][set damage 100]]
       palette:set-saturation damage
    ]


    ;this does the climate and local damage to the patches
if climate_change = True[
    ask patches[
      let turtle_count count turtles-here
      let local_damage turtle_count * local_damage_calibration;LOCAL DAMAGE

      ifelse development <= 0 [set development 0]
      [set development development - (emission_damage_modifier * TOTALemissions_pp) ; GLOBAL DAMAGE APPLIED
        set development development - local_damage
      ]
      ]
    ]


    update-plot-welfare
    update-plot-migration
    update-plot-displacement

    ;calculate total welfare over time
    let scale 1000000 ;(1mio)
    let new_welfare sum [wealth] of turtles / scale
    let new_welfare_p precision new_welfare 2
    set welfare welfare + new_welfare_p
    set welfare precision welfare 2


    if count turtles with [wealth > 0] = 0 [stop] ;stop model if no turtles
  tick

  ]

end

;------------------------------------



;------------------------------------
;REPORTER SECTION
;------------------------------------


;------------------------------------
;SETUP REPORTERS

to-report population ; returns a population number based on a random float
  ;that is used as a weight (does not scale correctly to the factor but is consistant)
  let totalPatches count patches
  let total_weight sum [pop_part] of patches
  let weight pop_part / totalpatches
  let wt weight * Population_factor
  let wtr ceiling wt
  report wtr
end

to-report base_wealth_reporter ;sets up how much wealth a turtle has
  ;is based on development of a patch and random normal draw
 if wealth_dist = True[
    let g random-gamma 10 3
    report g + 6.6 ; to make gamma and flat comparable, mean is bumped
  ]report 10

end


;------------------------------------
;GO REPORTERS

to-report local_emission_reporter ; this reports how much a patch emits
  let e1 economy / emission_calibration ; for balancing economy and emissions
  report e1
end

to-report economy_reporter; reports sum of turtles on patch
    let turtles-on-patch turtles-here
  report sum [wealth] of turtles-on-patch
end

; gives the overall world emission per patch
to-report TOTALemissions_pp
  let totalPatches count patches
  let totalemission sum [LOCALemission] of patches
  report totalemission / totalPatches
end

;lets turtles know the development of their patch
to-report patch_development_reporter
  let my-patch patch-here
  let d [development] of my-patch
  ifelse d > 0[report d][report 0]

end


;------------------------------------
;migration

;gives turtles the best patch
to-report max_patch
  let max-value -9999999 ; Use a large negative number
  let max-value-patch nobody

  ; Loop through neighboring patches
  ask patches in-radius radius [
    ; Check the value of development on each neighboring patch
    let neighbor-value [development] of self

    ; Update the max-value and max-value-patch if necessary
    if neighbor-value > max-value [
      set max-value neighbor-value
      set max-value-patch self
    ]
  ]
  report max-value-patch
end

;reports development of best patch
to-report max_dev
  let max-value -9999999 ; Use a large negative number
  ; Loop through neighboring patches
  ask patches in-radius radius [
    ; Check the value of the development on each neighboring patch
    let neighbor-value [development] of self
    ; Update the max-value and max-value-patch if they are larger
    if neighbor-value > max-value [
      set max-value neighbor-value
    ]
  ]
  report max-value
end




;migration and wealth gain anticipation
to migrate

  let result_list []
  let gain 0 ; Initialize sum

 ask turtles[
    let best_patch max_patch ;calls previous reporter
    let best_value max_dev ;calls previous reporter

   ; this creates the anticipation
    let diff best_value - patch_development_reporter
    let discount_rate 0.043
    let benefit wealth * diff
    let ant range anticipation
    ;Net Present value:
    foreach ant [
      x ->
      let disc_value benefit / (1 + discount_rate) ^ x

      ; Store the squared value in the result list
      set result_list lput disc_value result_list
      set gain gain + disc_value ;calculate overall gain from move
    ]
; this asks to move depeding on cost vs benefit
    if gain  > moving_cost[
      if wealth > moving_cost[
      move-to best_patch
      set wealth wealth - moving_cost
        set migrated migrated + 1]]
  ]

end

;------------------------------------
;displacement


;this is similar to the previous best_patch reporter for migration
to-report emergency_patch
  let max-value -9999999 ; Use a large negative number
  let max-value-patch nobody
  let my-value patch_development_reporter

  ; Loop through neighboring patches
  let emergency_radius radius
  ask patches in-radius emergency_radius [
    ; Check the value of the development on each neighboring patch
    let neighbor-value [development] of self

    ; Update the max-value and max-value-patch if necessary
    if neighbor-value > max-value [
      set max-value neighbor-value
      set max-value-patch self
    ]

  ]
  ifelse max-value > my-value[
    report max-value-patch][report patch-here]
end

;this is similar to migration, except that benefits are irrelevant, instead forcing migration if the current patch is too degraded
to emergency_migrate
  ask turtles[
    let patch_dev patch_development_reporter
    if patch_dev < 0.01[
    let best_patch max_patch
    let best_value max_dev

    if wealth > displacement_cost [
        if emergency_patch != patch-here[
        move-to emergency_patch
        set wealth 1 ;this also "punishes" displacement in welfare calculations strongly
        set shape "x"
        set size 1
        set emergency_migrated emergency_migrated + 1]
      ]
      ]
  ]

end

;------------------------------------


;------------------------------------
;Monitors
;------------------------------------


to-report migration
  let s sum [migrated] of turtles
  let c count turtles
  report s
end

to-report emergency_migrated_count
    let s sum [emergency_migrated] of turtles
  let c count turtles
  report s
end

to-report population_count
  let s count turtles
  let r count turtles with [wealth = 0]
  report s - r
end

to-report mean_wealth
  let s mean [wealth] of turtles
  report round s
end

to-report dead_count
  let s count turtles with [wealth = 0]
  report s
end

to-report could_mig
  let s count turtles with [wealth > moving_cost]
  report s
end


;------------------------------------
;BEHAVIOUSPACE REPORTERS

to-report welfare_r
  report welfare
end

to-report ticks_r
  report ticks
end

to-report migration_r
  report sum [migrated] of turtles
end




;------------------------------------
;PLOTTING


;all 3 plotting commands very similar, just different plots and different values

to update-plot-welfare
  ; Calculate the mean value of the patch variable
 set-current-plot "Welfare"
  ifelse count turtles > 0[
  let mean_value2 mean [wealth] of turtles
  let mean_value mean_value2 * count turtles
  ; Update the list of mean values
  set mean_values lput welfare mean_values

      plotxy ticks mean_value][plotxy ticks 0]
end

to update-plot-migration
  ; Calculate the mean value of the patch variable
 set-current-plot "Migration"
  ifelse count turtles > 0[
  let mean_value mean [migrated] of turtles

  ; Update the list of mean values
  set mean_values lput mean_value mean_values

      plotxy ticks mean_value][plotxy ticks 0]
end

to update-plot-displacement
  ; Calculate the mean value of the patch variable
 set-current-plot "Displacement"
  ifelse count turtles > 0[
  let mean_value mean [emergency_migrated] of turtles
  ; Update the list of mean values
  set mean_values lput mean_value mean_values

      plotxy ticks mean_value][plotxy ticks 0]
end
@#$#@#$#@
GRAPHICS-WINDOW
307
10
653
357
-1
-1
10.242424242424242
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
91
228
154
261
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
10
180
43
Population_factor
Population_factor
0
2000
450.0
25
1
NIL
HORIZONTAL

PLOT
10
365
640
515
Welfare
NIL
NIL
0.0
50.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

SLIDER
7
44
179
77
radius
radius
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
8
84
180
117
moving_cost
moving_cost
0
500
75.0
5
1
NIL
HORIZONTAL

BUTTON
22
227
88
260
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
164
227
262
260
NIL
check_vals
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
6
267
79
312
NIL
migration
17
1
11

MONITOR
85
268
180
313
displacement
emergency_migrated_count
17
1
11

MONITOR
182
269
239
314
pop
population_count
17
1
11

MONITOR
183
316
240
361
dead
dead_count
17
1
11

SWITCH
190
64
316
97
wealth_dist
wealth_dist
0
1
-1000

PLOT
12
520
642
670
Migration
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

SWITCH
185
101
337
134
climate_change
climate_change
0
1
-1000

MONITOR
86
316
179
361
NIL
mean_wealth
17
1
11

SLIDER
6
122
183
155
displacement_cost
displacement_cost
0
100
4.0
1
1
NIL
HORIZONTAL

PLOT
13
672
643
822
Displacement
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

SLIDER
6
158
178
191
anticipation
anticipation
0
10
2.0
1
1
NIL
HORIZONTAL

MONITOR
6
315
72
360
mig_pos
could_mig
17
1
11

MONITOR
242
269
331
314
welfare(mio)
welfare
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Moving_cost" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>welfare_r</metric>
    <metric>ticks_r</metric>
    <metric>migration_r</metric>
    <enumeratedValueSet variable="Population_factor">
      <value value="450"/>
    </enumeratedValueSet>
    <steppedValueSet variable="moving_cost" first="1" step="1" last="200"/>
    <enumeratedValueSet variable="climate_change">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth_dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="anticipation">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="displacement_cost">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Information incentives" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>welfare_r</metric>
    <metric>ticks_r</metric>
    <enumeratedValueSet variable="Population_factor">
      <value value="450"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moving_cost">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="climate_change">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radius">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth_dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="anticipation">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="displacement_cost">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
