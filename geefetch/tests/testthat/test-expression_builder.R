# test-expression_builder.R — Tests for the GEE REST API expression builder

test_that(".ee_const creates a constantValue node", {
  node <- .ee_const(42)
  expect_equal(node, list(constantValue = 42))
})

test_that(".ee_const handles different types", {
  expect_equal(.ee_const("hello")$constantValue, "hello")
  expect_equal(.ee_const(TRUE)$constantValue, TRUE)
  expect_equal(.ee_const(NULL)$constantValue, NULL)
  expect_equal(.ee_const(list(1, 2))$constantValue, list(1, 2))
})

test_that(".ee_call creates a functionInvocationValue node", {
  node <- .ee_call("Image.load", id = .ee_const("USGS/SRTMGL1_003"))
  expect_true("functionInvocationValue" %in% names(node))
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.load")
  expect_equal(inv$arguments$id$constantValue, "USGS/SRTMGL1_003")
})

test_that(".ee_expression wraps node with result and values", {
  node <- .ee_const(1)
  expr <- .ee_expression(node)
  expect_equal(expr$result, "0")
  expect_true("0" %in% names(expr$values))
  expect_equal(expr$values[["0"]], node)
})

test_that(".date_to_ms converts dates correctly", {
  # 2024-01-01 00:00:00 UTC = 1704067200 seconds
  ms <- .date_to_ms(as.Date("2024-01-01"))
  expect_equal(ms, 1704067200000)
})

test_that(".ee_date creates a Date function invocation", {
  node <- .ee_date(as.Date("2024-01-01"))
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Date")
  expect_equal(inv$arguments$value$constantValue, 1704067200000)
})

test_that(".ee_date_range creates a DateRange node", {
  node <- .ee_date_range(as.Date("2024-01-01"), as.Date("2024-12-31"))
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "DateRange")
  expect_true("start" %in% names(inv$arguments))
  expect_true("end" %in% names(inv$arguments))
})

test_that(".ee_load_collection creates ImageCollection.load", {
  node <- .ee_load_collection("MODIS/061/MOD13A2")
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "ImageCollection.load")
  expect_equal(inv$arguments$id$constantValue, "MODIS/061/MOD13A2")
})

test_that(".ee_load_image creates Image.load", {
  node <- .ee_load_image("USGS/SRTMGL1_003")
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.load")
})

test_that(".ee_filter_date creates Collection.filter with date filter", {
  col <- .ee_load_collection("MODIS/061/MOD13A2")
  node <- .ee_filter_date(col, as.Date("2024-01-01"), as.Date("2024-02-01"))
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Collection.filter")
  expect_true("collection" %in% names(inv$arguments))
  expect_true("filter" %in% names(inv$arguments))
})

test_that(".ee_first creates Collection.first", {
  col <- .ee_load_collection("TEST")
  node <- .ee_first(col)
  expect_equal(node$functionInvocationValue$functionName, "Collection.first")
})

test_that(".ee_select creates Image.select with band list", {
  img <- .ee_load_image("TEST")
  node <- .ee_select(img, c("B4", "B5"))
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.select")
  expect_equal(inv$arguments$bandSelectors$constantValue, list("B4", "B5"))
})

test_that(".ee_multiply is identity for factor = 1", {
  img <- .ee_load_image("TEST")
  result <- .ee_multiply(img, 1)
  expect_identical(result, img)

  result2 <- .ee_multiply(img, 1L)
  expect_identical(result2, img)
})

test_that(".ee_multiply creates Image.multiply for non-trivial factor", {
  img <- .ee_load_image("TEST")
  node <- .ee_multiply(img, 0.0001)
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.multiply")
})

test_that(".ee_add is identity for offset = 0", {
  img <- .ee_load_image("TEST")
  expect_identical(.ee_add(img, 0), img)
  expect_identical(.ee_add(img, 0L), img)
})

test_that(".ee_add creates Image.add for non-trivial offset", {
  img <- .ee_load_image("TEST")
  node <- .ee_add(img, -273.15)
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.add")
})

test_that(".ee_scale_offset chains multiply then add", {
  img <- .ee_load_image("TEST")
  node <- .ee_scale_offset(img, 0.02, -273.15)
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.add")
  # Inner should be multiply
  inner <- inv$arguments$image1$functionInvocationValue
  expect_equal(inner$functionName, "Image.multiply")
})

test_that(".ee_scale_offset skips identity operations", {
  img <- .ee_load_image("TEST")
  # scale=1, offset=0 → no-op
  expect_identical(.ee_scale_offset(img, 1, 0), img)
  # scale=1, offset non-zero → only add
  node <- .ee_scale_offset(img, 1, 10)
  expect_equal(node$functionInvocationValue$functionName, "Image.add")
  # scale non-1, offset=0 → only multiply
  node2 <- .ee_scale_offset(img, 0.5, 0)
  expect_equal(node2$functionInvocationValue$functionName, "Image.multiply")
})

test_that(".ee_feature_collection emits the invocation form the service accepts", {
  coords <- data.table::data.table(
    point_id = 1:2,
    lon = c(138.75, 145),
    lat = c(-34.5, -30)
  )
  node <- .ee_feature_collection(coords)
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Collection")
  feats <- inv$arguments$features$arrayValue$values
  expect_length(feats, 2L)
  f1 <- feats[[1L]]$functionInvocationValue
  expect_equal(f1$functionName, "Feature")
  geom <- f1$arguments$geometry$functionInvocationValue
  expect_equal(geom$functionName, "GeometryConstructors.Point")
  expect_equal(geom$arguments$coordinates$constantValue, list(138.75, -34.5))
  expect_equal(f1$arguments$metadata$constantValue, list(point_id = 1L))
  # No constantValue anywhere at the collection level: that is the
  # Dictionary-not-FeatureCollection defect.
  expect_null(node$constantValue)
})

test_that(".ee_feature_collection serialises a single point as a JSON array", {
  skip_if_not_installed("jsonlite")
  coords <- data.table::data.table(point_id = 1L, lon = 138.75, lat = -34.5)
  json <- jsonlite::toJSON(.ee_feature_collection(coords), auto_unbox = TRUE)
  expect_match(json, '"values":\\[\\{"functionInvocationValue"', fixed = FALSE)
  expect_match(json, '"coordinates":\\{"constantValue":\\[138.75,-34.5\\]\\}')
  expect_match(json, '"metadata":\\{"constantValue":\\{"point_id":1\\}\\}')
})

test_that(".ee_sample_regions creates correct expression", {
  img <- .ee_load_image("TEST")
  coords <- data.table::data.table(point_id = 1L, lon = 0, lat = 0)
  node <- .ee_sample_regions(img, coords, 1000L)
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.sampleRegions")
  expect_true("image" %in% names(inv$arguments))
  expect_equal(
    inv$arguments$collection$functionInvocationValue$functionName,
    "Collection"
  )
  expect_equal(inv$arguments$scale$constantValue, 1000L)
  expect_true(inv$arguments$geometries$constantValue)
})

test_that(".ee_reduce_regions wires reducer and collection", {
  img <- .ee_load_image("TEST")
  coords <- data.table::data.table(point_id = 1L, lon = 0, lat = 0)
  node <- .ee_reduce_regions(img, coords, "mean", 30L)
  inv <- node$functionInvocationValue
  expect_equal(inv$functionName, "Image.reduceRegions")
  expect_equal(inv$arguments$reducer$functionInvocationValue$functionName, "Reducer.mean")
  expect_equal(
    inv$arguments$collection$functionInvocationValue$functionName,
    "Collection"
  )
})

test_that(".build_grid produces correct structure", {
  skip_if_not_installed("sf")
  bbox <- c(xmin = 138, ymin = -36, xmax = 140, ymax = -34)
  grid <- .build_grid(bbox, scale = 1000L)

  expect_true("dimensions" %in% names(grid))
  expect_true("affineTransform" %in% names(grid))
  expect_equal(grid$crsCode, "EPSG:4326")

  at <- grid$affineTransform
  expect_equal(at$translateX, 138)
  expect_equal(at$translateY, -34)
  expect_true(at$scaleX > 0)
  expect_true(at$scaleY < 0)
  expect_true(grid$dimensions$width > 0)
  expect_true(grid$dimensions$height > 0)
})

test_that(".build_grid clamps to max_dim", {
  bbox <- c(xmin = 0, ymin = -50, xmax = 180, ymax = 50)
  expect_warning(
    grid <- .build_grid(bbox, scale = 30L, max_dim = 512L),
    "exceeds"
  )
  expect_true(grid$dimensions$width <= 512L)
  expect_true(grid$dimensions$height <= 512L)
})

test_that(".parse_features_to_dt handles typical GeoJSON features", {
  features <- list(
    list(
      type = "Feature",
      properties = list(point_id = 1, NDVI = 0.65, EVI = 0.45)
    ),
    list(
      type = "Feature",
      properties = list(point_id = 2, NDVI = 0.32, EVI = 0.21)
    )
  )
  dt <- .parse_features_to_dt(features)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("point_id", "NDVI", "EVI") %in% names(dt)))
  expect_equal(dt$NDVI, c(0.65, 0.32))
})

test_that(".parse_features_to_dt handles NULL properties gracefully", {
  features <- list(
    list(type = "Feature", properties = list(a = 1, b = NULL)),
    list(type = "Feature", properties = list(a = 2, b = 3))
  )
  dt <- .parse_features_to_dt(features)
  expect_equal(nrow(dt), 2L)
  expect_true(is.na(dt$b[1L]))
})

test_that(".ee_dataset_image filters by bounds and mosaics scene collections", {
  coords <- data.table::data.table(point_id = 1:2, lon = c(138, 145), lat = c(-34, -30))
  built <- .ee_dataset_image(
    .GEE_META$sentinel2_ndvi, "sentinel2_ndvi", as.Date("2023-01-05"),
    .ee_multipoint(coords)
  )
  expect_equal(built$band, "NDVI")
  flat <- unlist(built$node, use.names = FALSE)
  expect_true("ImageCollection.mosaic" %in% flat)
  expect_true("Filter.intersects" %in% flat)
  expect_true("GeometryConstructors.MultiPoint" %in% flat)
  expect_true("Image.updateMask" %in% flat)
  expect_false("Collection.first" %in% flat)
})

test_that(".ee_dataset_image takes the first image for global products", {
  built <- .ee_dataset_image(
    .GEE_META$era5_temp, "era5_temp", as.Date("2023-01-05"),
    .ee_bbox(c(xmin = 138, ymin = -35, xmax = 139, ymax = -34))
  )
  flat <- unlist(built$node, use.names = FALSE)
  expect_true("Collection.first" %in% flat)
  expect_true("GeometryConstructors.BBox" %in% flat)
  expect_equal(built$band, "temperature_2m")
})

test_that(".ee_dataset_image derives SLGA bands from depth and stat", {
  built <- .ee_dataset_image(
    .GEE_META$slga_phc, "slga_phc", NULL, NULL,
    list(depth = "30-60", stat = "ci_upper")
  )
  expect_equal(built$band, "pHc_030_060_95")
  flat <- unlist(built$node, use.names = FALSE)
  expect_true("CSIRO/SLGA/pHc" %in% flat)
  expect_false("Collection.filter" %in% flat)
})
