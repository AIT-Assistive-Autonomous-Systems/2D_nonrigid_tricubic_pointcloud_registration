# 2D non-rigid point cloud registration

## Introduction

This repository contains a prototype implementation of a 2D non-rigid point cloud registration algorithm. The algorithm is described in the paper "**Non-rigid point cloud registration using piece-wise tricubic polynomials as transformation model**".

<!-- TODO Add bibtex here -->

An efficient 3D implementation of this algorithm written in C++ can be found [here](https://github.com/AIT-Assistive-Autonomous-Systems/3D_nonrigid_tricubic_pointcloud_registration).

## Minimal example

A minimal example is provided in the `test` folder. It can be started with:

```matlab
cd test
minimal_example
```
This example registers two point clouds of a fish in a non-rigid manner. The result is:

![alt](docs/fish.png)

Source of the point clouds: *Myronenko, A.; Song, X.; Carreira-Perpinan, M. Non-rigid point set registration: Coherent point drift. Advances in neural
information processing systems 2006, 19.*
## GUI

We have implemented a graphical user interface (GUI) for testing the algorithm - it can be started with:

```matlab
cd test
run_nonrigidRegistrationGUI.m
```

![alt](docs/matlab-gui.png)

## Requirements

The prototype has been tested with *Matlab R2023a*. It requires the "Statistics and Machine Learning Toolbox".