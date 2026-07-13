# 20. Agriculture / Farm Management

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Farm operator managing fields, crops, livestock, inputs, yields, and compliance records.

**Core entities:** Field/Plot, Crop/Variety, Livestock/Herd, Input Application (seed/fertilizer/pesticide), Harvest/Yield, Weather Data, Equipment, Compliance Record

**Gotchas:**
- **Spatial data is fundamental** — fields are polygons, not names. Soil types vary within a field. Variable-rate application requires GIS integration. The dashboard needs map-based visualization with overlays.
- **Crop rotation is a multi-year dataset** — what was planted for the last 5 years affects what can be planted this year. The data model must track field-year-crop relationships across seasons.
- **Input application records are regulatory** — every pesticide application must record: product, EPA registration number, rate per acre, application method, wind speed, temperature, applicator certification, restricted entry interval. Missing any field means fines.
- **Weather integration is essential** — growing degree days, precipitation, frost dates, evapotranspiration drive decisions. On-farm weather station data must ingest automatically.
- **Livestock tracking is individual-animal granular** — ear tag/RFID, breed, birthdate, lineage, vaccinations, weight history, health events, movement history. For dairy: individual milk production records.
- **Harvest must reconcile with storage and sales** — bushels from Field 3 go to Bin A, sold to Elevator B at a specific grade and moisture. Moisture adjustment, drying costs, and basis pricing are standard calculations.

**Compliance:** EPA pesticide reporting, USDA organic certification (3-year transition), FSMA Produce Safety Rule, animal welfare regulations, water use permits, nutrient management plans, country-of-origin labeling, traceability (EU Farm to Fork).

**UX users expect:** Map-centric interface with field polygons, field activity timeline, input application form with regulatory fields, yield comparison (this year vs. 5-year average), livestock cards, weather dashboard with GDD accumulation, grain bin tracker.

**Seed data shape:** 8 fields as GeoJSON polygons with varied acreage (40-320 acres). 5 years of crop rotation history per field. 20 input application records with full regulatory fields (product, EPA number, rate, weather conditions, applicator cert). 3 years of harvest data with yields in bushels/acre. 50 livestock with individual records (ear tag, breed, vaccinations, weight history). 90 days of weather station data (temp, precip, wind). 4 grain bins with capacity and current fill levels. 2 equipment items with maintenance schedules.
