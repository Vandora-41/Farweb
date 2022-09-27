

// duplicates lots of code, but this proc needs to be as fast as possible.
/proc/create_lighting_overlays(zlevel = 0)
	var/area/A
	if(zlevel == 0) // populate all zlevels
		for(var/turf/T in turfs)
			if(T.dynamic_lighting)
				A = T.loc
				if(A.lighting_use_dynamic)
					var/atom/movable/lighting_overlay/O = PoolOrNew(/atom/movable/lighting_overlay, T)
					T.lighting_overlay = O

	else
		for(var/x = 1; x <= world.maxx; x++)
			for(var/y = 1; y <= world.maxy; y++)
				var/turf/T = locate(x, y, zlevel)
				if(T.dynamic_lighting)
					A = T.loc
					if(A.lighting_use_dynamic)
						var/atom/movable/lighting_overlay/O = PoolOrNew(/atom/movable/lighting_overlay, T)
						T.lighting_overlay = O