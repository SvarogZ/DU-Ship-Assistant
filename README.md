# DU-Ship-Assistant
Dual Universe script to find damage and fuel tanks if the ship has landed/docked

The script is designed to work with two screens.

One screen shows fuel tanks, another - current damage.

The script is adapted for huge constructs and is able to check a limited number of damaged elements in one cycle.

The script is able to point the element for easy finding.

The next elements should be connected:
- Core
- Screen for fuel
- Screen for damage
- All fuel tanks

**How to use**

Alt+1 - switch between fuel and damage information on the system screen.

Alt+2 - scroll up fuel tanks or damaged elements to point them

Alt+3 - scroll down fuel tanks or damaged elements to point them

Alt+9 - exit

**User-defined parameter**

***fuel_screen_number*** found screen number, 1 or 2, to interchange screens if required

***damage_screen_number*** found screen number, 1 or 2

***damaged_elements_to_check*** The number of elements checked in one cycle

***atmo_color***: color for atmo tanks

***space_color***: color for space tanks

***rocket_color***: color for rocket tanks

***font_size***: font size for the table

***font_color***: font color for the table

***screen_color***: screen background color

***no_damage_color***: "No Damage" text color

***progress_color***: "Progress..." text color

***damage_text_color***: damage text color for the system screen

***fuel_tank_text_color***: fuel tank text color for the system screen

***screen_text_shadow_color***: text shadow color for the system screen

***table_border_color***: table border color

***header_background_color***: table header background color

***header_text_color***: table header text color

***row_color_1***: table even line background color

***row_color_2***: table odd line background color

***update_time***: time in seconds to update data (one cycle)

***indicator_color***: indicator color

***pointer_max_distance***: distance in meters from element to start pointing

***pointer_fps***: pointer movement fps (not more than 30)

***pointer_speed***: pointer speed m/s


The next code should be placed in the right locations.

Place the main code to the unit.start.

Create a timer with the name “update”
```
-------------------------
-- FILTER UPDATE --------
-------------------------
update()
```

Create a timer with the name “point”
```
-------------------------
-- FILTER POINT ---------
-------------------------
pointElement()
```

Add to unit.stop
```
-------------------------
-- STOP -----------------
-------------------------
stop()
```

Create a filter for Alt+1
```
-------------------------
-- Alt+1 ----------------
-------------------------
changeElementsToScroll()
```

Create a filter for Alt+2
```
-------------------------
-- Alt+2 ----------------
-------------------------
activeElementIdUp()
```

Create a filter for Alt+3
```
-------------------------
-- Alt+3 ----------------
-------------------------
activeElementIdDown()
```

Create a filter for Alt+9
```
-------------------------
-- Alt+9 ----------------
-------------------------
unit.exit()
```
