import argparse
import copy
import logging
import pickle as pkl
import os
import random
import string
import time

import IPython
import matplotlib.pyplot as plt
import numpy as np
import scipy.stats

import database as db
import experiment_config as ec
import gripper

import sys
script_path = os.path.realpath(__file__)
script_directory = os.path.dirname(script_path)
library_directory = os.path.normpath(os.path.join(script_directory, "../../google/proto"))
sys.path.insert(0, library_directory)
import objectposes_pb2

if __name__ == '__main__':

    np.random.seed(100)
    parser = argparse.ArgumentParser()
    parser.add_argument('config')
    parser.add_argument('output_dest')
    args = parser.parse_args()

    logging.getLogger().setLevel(logging.INFO)

    # read config file
    config = ec.ExperimentConfig(args.config)
    database_filename = os.path.join(config['database_dir'], config['database_name'])
    database = db.Hdf5Database(database_filename, config)

    output_directory = args.output_dest

    zeke_gripper = gripper.RobotGripper.load("zeke")
    proto_poses = objectposes_pb2.ObjectPoses()

    for dataset_name in config['datasets'].keys():
        dataset = database.dataset(dataset_name)


        # label each object in the dataset with grasps
  
        obj_grasps = dataset.grasps("textured-0008192", "pr2")
        for grasp in obj_grasps:
            gripper_pose = grasp.gripper_transform(zeke_gripper)
            quaternion = gripper_pose.pose.rotation.quaternion
            translation = gripper_pose.translation
            proto_grasp = proto_poses.poses.add()
           
            #All of the crap for protobuff
            proto_translation = objectposes_pb2.Vector3D()
            proto_translation.x = translation[0]
            proto_translation.y = translation[1]
            proto_translation.z = translation[2]

            proto_quaternion = objectposes_pb2.Quaternion()
            proto_quaternion.x = quaternion[0]
            proto_quaternion.y = quaternion[1]
            proto_quaternion.z = quaternion[2]
            proto_quaternion.w = quaternion[3]

            proto_grasp.translation.CopyFrom(proto_translation)
            proto_grasp.rotation.CopyFrom(proto_quaternion)
            
            # pose_filename = os.path.join(output_dest + "pose_"+ str(i) + ".txt")
            # save_file = open(pose_filename, 'w')
            # np.save(save_file, quaternion)
            # save_file.close()


    database.close()


