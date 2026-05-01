This project is a Racket implementation for running INTERCAL.

To learn more about what this project is and how to run it, check the documentation,
which is written in Scribble and generated locally.

Source files:

- [Reference documentation](intercal/scribblings/intercal.scrbl)
- [Programming INTERCAL](intercal/scribblings/programming-intercal.scrbl)

To build the HTML documentation:

```sh
raco scribble --htmls +m --dest scribblings \
  intercal/scribblings/intercal.scrbl \
  intercal/scribblings/programming-intercal.scrbl
```

To view the documentation, open the two generated files:

scribblings/intercal/index.html
scribblings/programming-intercal/index.html
