context("colwise")

test_that("funs found in current environment", {
  f <- function(x) 1
  df <- data.frame(x = c(2:10, 1000))

  out <- summarise_all(df, funs(f, mean, median))
  expect_equal(out, data.frame(f = 1, mean = 105.4, median = 6.5))
})

test_that("can use character vectors", {
  df <- data.frame(x = 1:3)

  expect_equal(summarise_all(df, "mean"), summarise_all(df, funs(mean)))
  expect_equal(mutate_all(df, c(mean = "mean")), mutate_all(df, funs(mean = mean)))
})

test_that("can use bare functions", {
  df <- data.frame(x = 1:3)

  expect_equal(summarise_all(df, mean), summarise_all(df, funs(mean)))
  expect_equal(mutate_all(df, mean), mutate_all(df, funs(mean)))
})

test_that("default names are smallest unique set", {
  df <- data.frame(x = 1:3, y = 1:3)

  expect_named(summarise_at(df, vars(x:y), funs(mean)), c("x", "y"))
  expect_named(summarise_at(df, vars(x), funs(mean, sd)), c("mean", "sd"))
  expect_named(summarise_at(df, vars(x:y), funs(mean, sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
})

test_that("named arguments force complete namd", {
  df <- data.frame(x = 1:3, y = 1:3)
  expect_named(summarise_at(df, vars(x:y), funs(mean = mean)), c("x_mean", "y_mean"))
  expect_named(summarise_at(df, vars(x = x), funs(mean, sd)), c("x_mean", "x_sd"))
})

expect_classes <- function(tbl, expected) {
  classes <- unname(map_chr(tbl, class))
  classes <- paste0(substring(classes, 0, 1), collapse = "")
  expect_equal(classes, expected)
}

test_that("can select colwise", {
  columns <- iris %>% mutate_at(vars(starts_with("Petal")), as.character)
  expect_classes(columns, "nnccf")

  numeric <- iris %>% mutate_at(c(1, 3), as.character)
  expect_classes(numeric, "cncnf")

  character <- iris %>% mutate_at("Species", as.character)
  expect_classes(character, "nnnnc")
})

test_that("can probe colwise", {
  predicate <- iris %>% mutate_if(is.factor, as.character)
  expect_classes(predicate, "nnnnc")

  logical <- iris %>% mutate_if(c(TRUE, FALSE, TRUE, TRUE, FALSE), as.character)
  expect_classes(logical, "cnccf")
})

test_that("sql sources fail with bare functions", {
  expect_error(memdb_frame(x = 1) %>% mutate_all(mean) %>% collect())
})

test_that("empty selection does not select everything (#2009, #1989)", {
  expect_equal(mtcars, mutate_if(mtcars, is.factor, as.character))
})

test_that("error is thrown with improper additional arguments", {
  expect_error(mutate_all(mtcars, round, 0, 0), "3 arguments passed")
  expect_error(mutate_all(mtcars, mean, na.rm = TRUE, na.rm = TRUE), "Duplicate arguments")
})

test_that("fun_list is merged with new args", {
  funs <- funs(fn = bar)
  funs <- as_fun_list(funs, baz = "baz")
  expect_identical(funs$fn, ~bar(., baz = "baz"))
})


# Deprecated ---------------------------------------------------------

test_that("_each() and _all() families agree", {
  df <- data.frame(x = 1:3, y = 1:3)

  expect_warning(expect_equal(summarise_each(df, funs(mean)), summarise_all(df, mean)), "deprecated")
  expect_warning(expect_equal(summarise_each(df, funs(mean), x:y), summarise_at(df, vars(x:y), mean)), "deprecated")
  expect_warning(expect_equal(summarise_each(df, funs(mean), z = y), summarise_at(df, vars(z = y), mean)), "deprecated")

  expect_warning(expect_equal(mutate_each(df, funs(mean)), mutate_all(df, mean)), "deprecated")
  expect_warning(expect_equal(mutate_each(df, funs(mean), x:y), mutate_at(df, vars(x:y), mean)), "deprecated")
  expect_warning(expect_equal(mutate_each(df, funs(mean), z = y), mutate_at(df, vars(z = y), mean)), "deprecated")
})
