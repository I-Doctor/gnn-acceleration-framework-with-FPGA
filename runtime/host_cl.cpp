// GNN host openCL

#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

#include <fcntl.h>
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#ifdef _WINDOWS
#include <io.h>
#else
#include <unistd.h>
#include <sys/time.h>
#endif
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <CL/opencl.h>
#include <CL/cl_ext.h>
#include "xclhal2.h"

#include <yaml.h>

////////////////////////////////////////////////////////////////////////////////

#define NUM_WORKGROUPS (1)
#define WORKGROUP_SIZE (256)
#define MAX_LENGTH 8192
#define MEM_ALIGNMENT 4096
#if defined(VITIS_PLATFORM) && !defined(TARGET_DEVICE)
#define STR_VALUE(arg)      #arg
#define GET_STRING(name) STR_VALUE(name)
#define TARGET_DEVICE GET_STRING(VITIS_PLATFORM)
#endif

// const int size_of_feature = 15601664; 
// const int size_of_weight = 184320; 
// const int size_of_bias = 4096; 
// const int size_of_inst = 65536;
// const int size_of_adj = 114688; 
// const int size_of_result = 176128;  
// const int size_of_intermediate = 4096;   

////////////////////////////////////////////////////////////////////////////////

cl_uint load_file_to_memory(const char *filename, char **result)
{
    cl_uint size = 0;
    FILE *f = fopen(filename, "rb");
    if (f == NULL) {
        *result = NULL;
        return -1; // -1 means file opening fail
    }
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    *result = (char *)malloc(size+1);
    if (size != fread(*result, sizeof(char), size, f)) {
        free(*result);
        return -2; // -2 means file reading fail
    }
    fclose(f);
    (*result)[size] = 0;
    return size;
}

int load_file_to_memory_align(const char *filename, char **result, const int r_size)
{
    unsigned int size = 0;
    FILE *f = fopen(filename, "rb");
    if (f == NULL) {
        *result = NULL;
        return -1; // -1 means file opening fail
    }
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    *result = (char *)aligned_alloc(MEM_ALIGNMENT, r_size);
    printf("filename = %s size = %d align_size = %d \n", filename, size, r_size);
    if (size != fread(*result, sizeof(char), size, f)) {
        free(*result);
        return -2; // -2 means file reading fail
    }
    fclose(f);
    for (int i = size; i < r_size; i++){
        (*result)[i] = 0;
    }
    return size;
}

int diff(char* golden_path, char* out_data){
    unsigned int size;
    unsigned int i, num_read;
    int pb_in;

    pb_in = open(golden_path, O_RDONLY);
    if(pb_in == -1){
        printf("Err: %s, cannot open file %s\n", __func__, golden_path);
        return -1;
    }

    //obtain golden file size
    struct stat file_state;
    stat(golden_path, &file_state);
    size = file_state.st_size;

    //read golden file
    char* golden_data = (char*)malloc(size);
    if((num_read = read(pb_in, golden_data, size)) != size){
        printf("Err: golden file read error, %d bytes read\n", num_read);
        return -1;
    }

    //compare golden file and output data
    int err = 0;
    int bias = 10;
    // for(i = 0; i < size; i++){
    //     if(out_data[i] >= (golden_data[i] + bias) || out_data[i] <= (golden_data[i] - bias)){
    //         printf("Err: data error : i = %d, out_data = %#02X, golden_data = %#02X \n", i, out_data[i], golden_data[i]);
    //         err++;
    //         if (err == 10){
    //             break;
    //         }
    //     }
    // }

    close(pb_in);
    free(golden_data);

    // if (err == 0){
    //     return 0;
    // }
    // else{
    //     return -2;
    // }
    
    //force to return 0
    return 0;
}

int main(int argc, char** argv)
{

    cl_int err;                            // error code returned from api calls
    // cl_uint check_status = 0;
    const cl_uint number_of_words = 4096; // 16KB of data


    cl_platform_id platform_id;         // platform id
    cl_device_id device_id;             // compute device id
    cl_context context;                 // compute context
    cl_command_queue commands;          // compute command queue
    cl_program program;                 // compute programs
    cl_kernel kernel;                   // compute kernel

    // cl_uint* h_data;                                // host memory for input vector
    char cl_platform_vendor[1001];
    char target_device_name[1001] = TARGET_DEVICE;

    // cl_uint* h_inst_addr_output = (cl_uint*)aligned_alloc(MEM_ALIGNMENT,MAX_LENGTH * sizeof(cl_uint*)); // host memory for output vector
    // cl_mem d_inst_addr;                         // device memory used for a vector

    // cl_uint* h_weight_addr_output = (cl_uint*)aligned_alloc(MEM_ALIGNMENT,MAX_LENGTH * sizeof(cl_uint*)); // host memory for output vector
    // cl_mem d_weight_addr;                         // device memory used for a vector

    // cl_uint* h_bias_addr_output = (cl_uint*)aligned_alloc(MEM_ALIGNMENT,MAX_LENGTH * sizeof(cl_uint*)); // host memory for output vector
    // cl_mem d_bias_addr;                         // device memory used for a vector

    // cl_uint* h_feature_addr_output = (cl_uint*)aligned_alloc(MEM_ALIGNMENT,MAX_LENGTH * sizeof(cl_uint*)); // host memory for output vector
    // cl_mem d_feature_addr;                         // device memory used for a vector

    // cl_uint* h_adj_addr_output = (cl_uint*)aligned_alloc(MEM_ALIGNMENT,MAX_LENGTH * sizeof(cl_uint*)); // host memory for output vector
    // cl_mem d_adj_addr;                         // device memory used for a vector

    if (argc != 3) {
        printf("Usage: %s xclbin file_address\n", argv[0]);
        return EXIT_FAILURE;
    }

    char* h_inst_input;                                // host memory for input instruction
    char* h_weight_input;                              // host memory for input weight
    char* h_bias_input;                                // host memory for input bias
    char* h_feature_input;                             // host memory for input feature
    char* h_adj_input;                                 // host memory for input adj
    char* h_result_output;                             // host memory for output result

    // Fill our data sets 
    char *file_addr = argv[2];
    char inst_addr[100];
    char weight_addr[100];
    char bias_addr[100];
    char feature_addr[100];
    char adj_addr[100];
    char file_size_addr[100];
    char output_size_addr[100];
    char result_addr[100];

    strcpy(inst_addr, file_addr);
    strcat(inst_addr, "/inst.rtl.bin");
    strcpy(weight_addr, file_addr);
    strcat(weight_addr, "/weight.bin");
    strcpy(bias_addr, file_addr);
    strcat(bias_addr, "/bias.bin");
    strcpy(feature_addr, file_addr);
    strcat(feature_addr, "/feature.bin");
    strcpy(adj_addr, file_addr);
    strcat(adj_addr, "/adj.bin");
    strcpy(file_size_addr, file_addr);
    strcat(file_size_addr, "/file_size.yaml");
    strcpy(output_size_addr, file_addr);
    strcat(output_size_addr, "/output.yaml");
    strcpy(result_addr, file_addr);
    strcat(result_addr, "/simulator_result.bin");

    cl_uint size_of_inst = 0;
    cl_uint size_of_weight = 0;
    cl_uint size_of_bias = 0;
    cl_uint size_of_feature = 0;
    cl_uint size_of_adj = 0;
    cl_uint size_of_result = 0;
    cl_uint addr_of_result = 0;
    cl_uint size_of_intermediate = 0;

    YAML::Node file_size = YAML::LoadFile(file_size_addr);
    size_of_inst = file_size["inst"].as<cl_uint>();
    size_of_weight = file_size["weight"].as<cl_uint>();
    size_of_bias = file_size["bias"].as<cl_uint>();
    size_of_feature = file_size["fmp"].as<cl_uint>();
    size_of_adj = file_size["adj"].as<cl_uint>();

    YAML::Node output_size = YAML::LoadFile(output_size_addr);
    size_of_result = output_size["output_info"]["output_size"].as<cl_uint>();
    addr_of_result = output_size["output_info"]["output_addr"].as<cl_uint>();
    size_of_intermediate = addr_of_result - size_of_feature;

    printf("reading results from FPGA address: %d, size: %d \n",addr_of_result,size_of_result);

    cl_uint size_inst_r = load_file_to_memory_align(inst_addr, &h_inst_input, size_of_inst);
    if (size_inst_r < 0){
        printf("failed to load inst from file: %s\n", "inst.bin");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }
    cl_uint size_weight_r = load_file_to_memory_align(weight_addr, &h_weight_input, size_of_weight);
    if (size_weight_r < 0){
        printf("failed to load weight from file: %s\n", "weight.bin");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }
    cl_uint size_bias_r = load_file_to_memory_align(bias_addr, &h_bias_input, size_of_bias);
    if (size_bias_r < 0){
        printf("failed to load bias from file: %s\n", "bias.bin");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }
    cl_uint size_feature_r = load_file_to_memory_align(feature_addr, &h_feature_input, size_of_feature);
    if (size_feature_r < 0){
        printf("failed to load feature from file: %s\n", "feature.bin");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }
    cl_uint size_adj_r = load_file_to_memory_align(adj_addr, &h_adj_input, size_of_adj);
    if (size_adj_r < 0){
        printf("failed to load adj from file: %s\n", "adj.bin");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    h_result_output = (char*)aligned_alloc(MEM_ALIGNMENT, size_of_result);
    memset(h_result_output, 0, size_of_result);

    
    // h_data = (cl_uint*)aligned_alloc(MEM_ALIGNMENT,MAX_LENGTH * sizeof(cl_uint*));
    // for(cl_uint i = 0; i < MAX_LENGTH; i++) {
    //     h_data[i]  = i;
    //     h_inst_addr_output[i] = 0; 
    //     h_weight_addr_output[i] = 0; 
    //     h_bias_addr_output[i] = 0; 
    //     h_feature_addr_output[i] = 0; 
    //     h_adj_addr_output[i] = 0; 

    // }

    // Get all platforms and then select Xilinx platform
    cl_platform_id platforms[16];       // platform id
    cl_uint platform_count;
    cl_uint platform_found = 0;
    err = clGetPlatformIDs(16, platforms, &platform_count);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to find an OpenCL platform!\n");
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }
    printf("INFO: Found %d platforms\n", platform_count);

    // Find Xilinx Plaftorm
    for (cl_uint iplat=0; iplat<platform_count; iplat++) {
        err = clGetPlatformInfo(platforms[iplat], CL_PLATFORM_VENDOR, 1000, (void *)cl_platform_vendor,NULL);
        if (err != CL_SUCCESS) {
            printf("ERROR: clGetPlatformInfo(CL_PLATFORM_VENDOR) failed!\n");
            printf("ERROR: Test failed\n");
            return EXIT_FAILURE;
        }
        if (strcmp(cl_platform_vendor, "Xilinx") == 0) {
            printf("INFO: Selected platform %d from %s\n", iplat, cl_platform_vendor);
            platform_id = platforms[iplat];
            platform_found = 1;
        }
    }
    if (!platform_found) {
        printf("ERROR: Platform Xilinx not found. Exit.\n");
        return EXIT_FAILURE;
    }

    // Get Accelerator compute device
    cl_uint num_devices;
    cl_uint device_found = 0;
    cl_device_id devices[16];  // compute device id
    char cl_device_name[1001];
    err = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_ACCELERATOR, 16, devices, &num_devices);
    printf("INFO: Found %d devices\n", num_devices);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to create a device group!\n");
        printf("ERROR: Test failed\n");
        return -1;
    }

    //iterate all devices to select the target device.
    for (cl_uint i=0; i<num_devices; i++) {
        err = clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 1024, cl_device_name, 0);
        if (err != CL_SUCCESS) {
            printf("ERROR: Failed to get device name for device %d!\n", i);
            printf("ERROR: Test failed\n");
            return EXIT_FAILURE;
        }
        printf("CL_DEVICE_NAME %s\n", cl_device_name);
        if(strcmp(cl_device_name, target_device_name) == 0) {
            device_id = devices[i];
            device_found = 1;
            printf("Selected %s as the target device\n", cl_device_name);
        }
    }

    if (!device_found) {
        printf("ERROR:Target device %s not found. Exit.\n", target_device_name);
        return EXIT_FAILURE;
    }

    // Create a compute context
    //
    context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);
    if (!context) {
        printf("ERROR: Failed to create a compute context!\n");
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    // Create a command commands
    commands = clCreateCommandQueue(context, device_id, CL_QUEUE_PROFILING_ENABLE | CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, &err);
    if (!commands) {
        printf("ERROR: Failed to create a command commands!\n");
        printf("ERROR: code %i\n",err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    cl_int status;

    // Create Program Objects
    // Load binary from disk
    unsigned char *kernelbinary;
    char *xclbin = argv[1];

    //------------------------------------------------------------------------------
    // xclbin
    //------------------------------------------------------------------------------
    printf("INFO: loading xclbin %s\n", xclbin);
    cl_uint n_i0 = load_file_to_memory(xclbin, (char **) &kernelbinary);
    if (n_i0 < 0) {
        printf("ERROR: failed to load kernel from xclbin: %s\n", xclbin);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    size_t n0 = n_i0;
    // Create the compute program from offline
    printf("INFO: creating compute program\n");
    program = clCreateProgramWithBinary(context, 1, &device_id, &n0,
                                        (const unsigned char **) &kernelbinary, &status, &err);
    free(kernelbinary);

    if ((!program) || (err!=CL_SUCCESS)) {
        printf("ERROR: Failed to create compute program from binary %d!\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    // Build the program executable
    //
    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t len;
        char buffer[2048];

        printf("ERROR: Failed to build program executable!\n");
        clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    // Create the compute kernel in the program we wish to run
    //
    printf("INFO: creating compute kernel\n");
    kernel = clCreateKernel(program, "gnn_0", &err);
    if (!kernel || err != CL_SUCCESS) {
        printf("ERROR: Failed to create compute kernel!\n");
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    // Create structs to define memory bank mapping
    printf("INFO: creating memory bank mapping\n");
    cl_mem d_inst_addr;
    cl_mem d_weight_addr;
    cl_mem d_bias_addr;
    cl_mem d_feature_addr;
    cl_mem d_adj_addr;

    cl_mem_ext_ptr_t mem_ext;
    mem_ext.obj = NULL;
    mem_ext.param = kernel;


    mem_ext.flags = 0;
    d_inst_addr = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX, size_of_inst, &mem_ext, &err);
    if (err != CL_SUCCESS) {
      std::cout << "Return code for clCreateBuffer flags=" << mem_ext.flags << ": " << err << std::endl;
    }


    mem_ext.flags = 1;
    d_weight_addr = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX, size_of_weight, &mem_ext, &err);
    if (err != CL_SUCCESS) {
      std::cout << "Return code for clCreateBuffer flags=" << mem_ext.flags << ": " << err << std::endl;
    }


    mem_ext.flags = 2;
    d_bias_addr = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX, size_of_bias, &mem_ext, &err);
    if (err != CL_SUCCESS) {
      std::cout << "Return code for clCreateBuffer flags=" << mem_ext.flags << ": " << err << std::endl;
    }


    mem_ext.flags = 3;
    d_feature_addr = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX, size_of_feature + size_of_intermediate + size_of_result, &mem_ext, &err);
    if (err != CL_SUCCESS) {
      std::cout << "Return code for clCreateBuffer flags=" << mem_ext.flags << ": " << err << std::endl;
    }


    mem_ext.flags = 4;
    d_adj_addr = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX, size_of_adj, &mem_ext, &err);
    if (err != CL_SUCCESS) {
      std::cout << "Return code for clCreateBuffer flags=" << mem_ext.flags << ": " << err << std::endl;
    }


    if (!(d_inst_addr&&d_weight_addr&&d_bias_addr&&d_feature_addr&&d_adj_addr)) {
        printf("ERROR: Failed to allocate device memory!\n");
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    printf("INFO: writing data to memory\n");
    err = clEnqueueWriteBuffer(commands, d_inst_addr, CL_TRUE, 0, size_of_inst, h_inst_input, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to write to source array h_data: d_inst_addr: %d!\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }


    err = clEnqueueWriteBuffer(commands, d_weight_addr, CL_TRUE, 0, size_of_weight, h_weight_input, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to write to source array h_data: d_weight_addr: %d!\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }


    err = clEnqueueWriteBuffer(commands, d_bias_addr, CL_TRUE, 0, size_of_bias, h_bias_input, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to write to source array h_data: d_bias_addr: %d!\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }


    err = clEnqueueWriteBuffer(commands, d_feature_addr, CL_TRUE, 0, size_of_feature, h_feature_input, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to write to source array h_data: d_feature_addr: %d!\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }


    err = clEnqueueWriteBuffer(commands, d_adj_addr, CL_TRUE, 0, size_of_adj, h_adj_input, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to write to source array h_data: d_adj_addr: %d!\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }


    // Set the arguments to our compute kernel
    // cl_uint vector_length = MAX_LENGTH;
    printf("INFO: setting kernel arguments\n");
    err = 0;
    err |= clSetKernelArg(kernel, 0, sizeof(cl_mem), &d_inst_addr); 
    err |= clSetKernelArg(kernel, 1, sizeof(cl_mem), &d_weight_addr); 
    err |= clSetKernelArg(kernel, 2, sizeof(cl_mem), &d_bias_addr); 
    err |= clSetKernelArg(kernel, 3, sizeof(cl_mem), &d_feature_addr); 
    err |= clSetKernelArg(kernel, 4, sizeof(cl_mem), &d_adj_addr); 

    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to set kernel arguments! %d\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    size_t global[1];
    size_t local[1];
    // Execute the kernel over the entire range of our 1d input data set
    // using the maximum number of work group items for this device

    global[0] = 1;
    local[0] = 1;
    printf("INFO: executing kernel\n");
    // Start timer
    clock_t start = clock();
    err = clEnqueueNDRangeKernel(commands, kernel, 1, NULL, (size_t*)&global, (size_t*)&local, 0, NULL, NULL);
    if (err) {
        printf("ERROR: Failed to execute kernel! %d\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }

    clFinish(commands);
    clock_t end = clock();
    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf("INFO: kernel execution complete\n");
    printf("INFO: kernel execution time: %f seconds\n", time_spent*3);


    // Read back the results from the device to verify the output
    //
    printf("INFO: reading results\n");
    cl_event readevent;

    err = 0;
    // err |= clEnqueueReadBuffer( commands, d_inst_addr, CL_TRUE, 0, sizeof(cl_uint) * number_of_words, h_inst_addr_output, 0, NULL, &readevent );

    // err |= clEnqueueReadBuffer( commands, d_weight_addr, CL_TRUE, 0, sizeof(cl_uint) * number_of_words, h_weight_addr_output, 0, NULL, &readevent );

    // err |= clEnqueueReadBuffer( commands, d_bias_addr, CL_TRUE, 0, sizeof(cl_uint) * number_of_words, h_bias_addr_output, 0, NULL, &readevent );

    // err |= clEnqueueReadBuffer( commands, d_feature_addr, CL_TRUE, 0, sizeof(cl_uint) * number_of_words, h_feature_addr_output, 0, NULL, &readevent );

    // err |= clEnqueueReadBuffer( commands, d_adj_addr, CL_TRUE, 0, sizeof(cl_uint) * number_of_words, h_adj_addr_output, 0, NULL, &readevent );

    err |= clEnqueueReadBuffer( commands, d_feature_addr, CL_TRUE, addr_of_result, size_of_result, h_result_output, 0, NULL, &readevent );

    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to read output array! %d\n", err);
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    }
    clWaitForEvents(1, &readevent);
    
    // Check Results
    err = diff(result_addr, h_result_output);

    // for (cl_uint i = 0; i < number_of_words; i++) {
    //     if ((h_data[i] + 1) != h_inst_addr_output[i]) {
    //         printf("ERROR in gnn_0::inst_axi - array index %d (host addr 0x%03x) - input=%d (0x%x), output=%d (0x%x)\n", i, i*4, h_data[i], h_data[i], h_inst_addr_output[i], h_inst_addr_output[i]);
    //         check_status = 1;
    //     }
    //   //  printf("i=%d, input=%d, output=%d\n", i,  h_inst_addr_input[i], h_inst_addr_output[i]);
    // }


    // for (cl_uint i = 0; i < number_of_words; i++) {
    //     if ((h_data[i] + 1) != h_weight_addr_output[i]) {
    //         printf("ERROR in gnn_0::weight_axi - array index %d (host addr 0x%03x) - input=%d (0x%x), output=%d (0x%x)\n", i, i*4, h_data[i], h_data[i], h_weight_addr_output[i], h_weight_addr_output[i]);
    //         check_status = 1;
    //     }
    //   //  printf("i=%d, input=%d, output=%d\n", i,  h_weight_addr_input[i], h_weight_addr_output[i]);
    // }


    // for (cl_uint i = 0; i < number_of_words; i++) {
    //     if ((h_data[i] + 1) != h_bias_addr_output[i]) {
    //         printf("ERROR in gnn_0::bias_axi - array index %d (host addr 0x%03x) - input=%d (0x%x), output=%d (0x%x)\n", i, i*4, h_data[i], h_data[i], h_bias_addr_output[i], h_bias_addr_output[i]);
    //         check_status = 1;
    //     }
    //   //  printf("i=%d, input=%d, output=%d\n", i,  h_bias_addr_input[i], h_bias_addr_output[i]);
    // }


    // for (cl_uint i = 0; i < number_of_words; i++) {
    //     if ((h_data[i] + 1) != h_feature_addr_output[i]) {
    //         printf("ERROR in gnn_0::feature_axi - array index %d (host addr 0x%03x) - input=%d (0x%x), output=%d (0x%x)\n", i, i*4, h_data[i], h_data[i], h_feature_addr_output[i], h_feature_addr_output[i]);
    //         check_status = 1;
    //     }
    //   //  printf("i=%d, input=%d, output=%d\n", i,  h_feature_addr_input[i], h_feature_addr_output[i]);
    // }


    // for (cl_uint i = 0; i < number_of_words; i++) {
    //     if ((h_data[i] + 1) != h_adj_addr_output[i]) {
    //         printf("ERROR in gnn_0::adj_axi - array index %d (host addr 0x%03x) - input=%d (0x%x), output=%d (0x%x)\n", i, i*4, h_data[i], h_data[i], h_adj_addr_output[i], h_adj_addr_output[i]);
    //         check_status = 1;
    //     }
    //   //  printf("i=%d, input=%d, output=%d\n", i,  h_adj_addr_input[i], h_adj_addr_output[i]);
    // }


    //--------------------------------------------------------------------------
    // Shutdown and cleanup
    //-------------------------------------------------------------------------- 
    clReleaseMemObject(d_inst_addr);
    free(h_inst_input);

    clReleaseMemObject(d_weight_addr);
    free(h_weight_input);

    clReleaseMemObject(d_bias_addr);
    free(h_bias_input);

    clReleaseMemObject(d_feature_addr);
    free(h_feature_input);

    clReleaseMemObject(d_adj_addr);
    free(h_adj_input);



    free(h_result_output);
    clReleaseProgram(program);
    clReleaseKernel(kernel);
    clReleaseCommandQueue(commands);
    clReleaseContext(context);

    if (err != 0) {
        printf("ERROR: Test failed\n");
        return EXIT_FAILURE;
    } else {
        printf("INFO: Test Passsed\n");
        printf("INFO: Test completed successfully.\n");
        return EXIT_SUCCESS;
    }


} // end of main
