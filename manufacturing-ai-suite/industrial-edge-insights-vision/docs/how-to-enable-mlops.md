# Enable MLOps using Model Registry
Industrial Edge Insights Vision can also be used to demonstrate MLOps workflow using Model Registry microservice.
With this feature, during runtime, you can download a new model from the registry and restart the pipeline with the new model.

## Contents

### Steps

> The following steps assume a pipeline is already running on DLStreamer Pipeline Server that you wish to update with a new model. If you would like to launch a sample pipeline for this demonstration, see [here](#launch-a-pipeline-in-dlstreamer-pipeline-server).

1. List all the registered models in the model registry
    ```sh
    curl 'http://<HOST_IP>:32002/models'
    ```
    If you do not have a model available, follow the steps [here](#upload-a-model-to-model-registry) to upload a sample model in Model Registry

2. Check the instance ID of the currently running pipeline to use it for the next step.
   ```sh
   curl --location -X GET http://<HOST_IP>:8080/pipelines/status
   ```
   > NOTE- Replace the port in the curl request according to the deployment method i.e. default 8080 for compose based.

3. Restart the model with a new model from Model Registry.
    The following curl command downloads the model from Model Registry using the specs provided in the payload. Upon download, the running pipeline is restarted with replacing the older model with this new model.
    ```sh
    curl 'http://<HOST_IP>:8080/pipelines/user_defined_pipelines/pallet_defect_detection_mlops/<instance_id_of_currently_running_pipeline>/models' \
    --header 'Content-Type: application/json' \
    --data '{
    "project_name": "pallet-defect-detection",
    "version": "v1",
    "category": "Detection",
    "architecture": "YOLO",
    "precision": "fp32",
    "deploy": true,
    "pipeline_element_name": "detection",
    "origin": "Geti",
    "name": "YOLO_Test_Model"
    }'
   ```

    > NOTE- The data above assumes there is a model in the registry that contains these properties. Also, the pipeline name that follows `user_defined_pipelines/`, will affect the `deployment` folder name.

4. View the WebRTC streaming on `http://<HOST_IP>:<mediamtx-port>/<peer-str-id>` by replacing `<peer-str-id>` with the value used in the original cURL command to start the pipeline.

    ![Example of a WebRTC streaming using default mediamtx-port 31111](./docs/user-guide/images/webrtc-streaming.png)

5. You can also stop any running pipeline by using the pipeline instance "id"
   ```sh
   curl --location -X DELETE http://<HOST_IP>:8080/pipelines/{instance_id}
   ```

## Additional Setup

### Launch a pipeline in DLStreamer Pipeline Server
> TODO whether to use sample_start to start the pipeline for this ?
### Upload a model to Model Registry
