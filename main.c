#include <stdio.h>
#include <math.h>

int euclids_algorithm(int a, int b){
  if(b%a == 0){
    return a;
  }
  else{
    return euclids_algorithm(b%a, a);
  }
}

int sum_array_integer(int a[], int s){
  int sum = 0;
  for(int i = 0; i < s; i++){
    sum = sum + a[i];
  }
  return sum;
}

float sum_array_float(float a[], int s){
  float sum = 0.0;
  for(int i = 0; i < s; i++){
    sum = sum + a[i];
  }
  return sum;
}



// Print Array

void print_array_integer(int a[], int s){
  for(int i = 0; i < s; i++){
    printf("integer[%d] = %d\n", i, a[i]);
  }
}
void print_array_float(float a[], int s){
  for(int i = 0; i < s; i++){
    printf("integer[%d] = %0.3f\n", i, a[i]);
  }
}

void selection_sort_integer(int a[], int s){
  //Outer loop repeating process for all s elements
  for(int i = 0; i < s-1; i++){
    int currMin = i;
    
    for(int j = i+1; j < s; j++){
      //Inner Loop keeps track of current minimum
      if(a[j] < a[currMin]){
	      currMin = j;
      }
    }
    //Swap
    int z = a[currMin];
    a[currMin] = a[i];
    a[i] = z;
  }
}
void selection_sort_float(float a[], int s){
  for(int i = 0; i < s-1; i++){
    int currMin = i;
    for(int j = i+1; j < s; j++){
      if(a[j] < a[currMin]){
	      currMin = j;
      }
    }
    float z = a[currMin];
    a[currMin] = a[i];
    a[i] = z;
  }
}

float myabs(float a){
  if (a >= 0.0){
    return a;
  }
  return 0.0-a;
}

float myround(float x) {
  float oX = x*10;
  float x1 = myabs(x)*10;
  int x2 = myabs(x)*10;
  float x3 = x1- (float)x2;
  float x4 = x3*10;
  if(x4 >= 5){
    if(oX < 0){
      return oX-1;
    }
    return oX+1;
  }
  return oX;
}
float myround2(float x){
  float x7 = x/10;
  float oX = x7*10;
  float x1 = myabs(x7)*10;
  int x2 = myabs(x7)*10;
  float x3 = x1- (float)x2;
  float x4 = x3*10;
  printf("%f\n", x4);
  if(x4 >= 5){
    if(oX < 0){
      return (oX-1);
    }
    return (oX+1);
  }
  return oX;
}
void graph_sin(float c){
  //Four Quadrants of Graph
  char gridPos[11][36];
  char gridNeg[11][36];
  char gridPos2[11][36];
  char gridNeg2[11][36];

  //Init with spaces
  for(int y = 0; y < 11; y++){
    for(int x = 0; x < 36; x++){
      gridPos[y][x] = ' ';
      gridPos2[y][x] = ' ';
      gridNeg[y][x] = ' ';
      gridNeg2[y][x] = ' ';
    }
  }

  //Left Half Evaluate
  for(int x1 = 0; x1 < 36; x1++){
    float x = x1*0.1;
    float y = sin(c*x);
    int y1 = (int) myround(y);
    if(y1 > 0){
      gridPos[y1][x1] = '*';
    }
    else{
      y1 = 0 - y1;
      gridNeg[y1][x1] = '*';
    }
  }
  //Right Half Evaluate
  for(int x1 = 0; x1 < 36; x1++){
    float x = x1*-0.1;
    float y = sin(c*x);
    int y1 = (int) myround(y);
    if(y1 > 0){
      gridPos2[y1][x1] = '*';
    }
    else{
      y1 = 0 - y1;
      gridNeg2[y1][x1] = '*';
    }
  }
  
  // Print graph
  printf("\n1.50|\n1.40|\n1.30|\n1.20|\n1.10|\n");
  //Top Half
  for(int y = 10; y > 0; y--){
    float y1 = y*0.1;
    printf("%0.2f|", y1);
    for(int x = 35; x > 0; x--){//Left Half
      printf("%c", gridPos2[y][x]);

    }
    for(int x = 0; x < 36; x++){//Right Half
      printf("%c", gridPos[y][x]);
    }

	  
    printf("\n");
  }
  //Bottom Half
  for(int y = 0; y < 11; y++){
    float y1 = y*0.1;
    printf("-%0.1f|", y1);
    for(int x = 35; x > 0; x--){//Left Half
      printf("%c", gridNeg2[y][x]);
    }
    for(int x = 0; x < 36; x++){//Right Half
      printf("%c", gridNeg[y][x]);
    }
    printf("\n");
  }
  printf("-1.1|\n-1.2|\n-1.3|\n-1.4|\n-1.5|\n");
  
  
  printf("     ------------------------------------------------------------------------\n");
  printf("         -3        -2        -1         0         1         2          3\n");
  
}
int main(int argc, char *argv[]) {

	// Local variables
	// NOTE: this is where you will want to add some new variables
	float f_array[20] = {20.23,
  1.0,
28.6,
25.29,
26.19,
4.8,
12.10,
26.30,
0.7,
8.8,
25.0,
9.23,
0.30,
22.17,
9.12,
23.6,
1.16,
1.20,
14.5,
11.3};
	int i_array[20];
  int i;

	// First, lets read in the float numbers to process

  /*
	for (i=0; i<20; i++) {
		scanf("%f", &f_array[i]);
	}
  */
  //printf("%f", myround2(63.554));
	// Convert the float arrays 
	for(int b = 0; b < 20; b++){
	  if(f_array[b] >= 10){
	    f_array[b] = f_array[b] * M_PI;
	  }
	  else{
	    f_array[b] = f_array[b] * 8.4;
	  }
	}

	// Make the integer array
	for(int c = 0; c < 20; c++){
	  int r = (int) myround2(f_array[c]);
	  if(r < 0){
	    i_array[c] = 0 - r;
	  }
	  else{
	    i_array[c] = r;
	  }
	}
  printf("The array of floats: ");
	print_array_float(f_array, 20);
  printf("The array of integers: ");
	print_array_integer(i_array, 20);
	
	float sumFloat = sum_array_float(f_array, 20);
	int sumInt = sum_array_integer(i_array, 20);
  printf("The sum of the array of floats is %0.3f\n", sumFloat);
	printf("The sum of the array of integers is %d\n", sumInt);

	
	// Get gcd of adjacent elements
	for(int a = 0; a < 19; a+=1){
	  int g = euclids_algorithm(i_array[a], i_array[a+1]);
	  printf("GCD(%d, %d) = %d\n", i_array[a], i_array[a+1], g);
	}

	//Selection Sort
	selection_sort_integer(i_array, 20);
	selection_sort_float(f_array, 20);
	printf("The sorted array of floats: ");
	print_array_float(f_array, 20);
  printf("The sorted array of integers: ");
	print_array_integer(i_array, 20);

	//Sin Function
  printf("Graph of y = sin(1.0 * x)\n");
	graph_sin(1.0);
  printf("Graph of y = sin(1.5 * x)\n");
	graph_sin(1.5);
  printf("Graph of y = sin(2.0 * x)\n");
	graph_sin(2.0);
  printf("Graph of y = sin(3.0 * x)\n");
	graph_sin(3.0);

	// Return successfully
	return(0);
}

