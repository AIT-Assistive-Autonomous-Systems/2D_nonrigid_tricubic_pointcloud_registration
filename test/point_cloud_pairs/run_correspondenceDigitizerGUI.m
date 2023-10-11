clc; clear all; close all;

addpath('../../src');

ptCloud1Filepath = 'dataset07_hand/pcFix.csv';
ptCloud2Filepath = 'dataset07_hand/pcMov.csv';

correspondenceDigitizerGUI(ptCloud1Filepath, ptCloud2Filepath);