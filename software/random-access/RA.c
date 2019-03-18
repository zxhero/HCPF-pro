#include"../HCPF.h"

/*test MMIO read speed*/
void CacheMissAccess(){
    printk("start loop 1\n");
    unsigned long begin = rdcycle();
    //int t;
    int j;
    int* p;
    int sum = 0;
    for(  p = (int*)0x80000000,  j=0; j < 64;j++, p = (int*)((char*)p + 64)){  //1536
        sum += *(int*)p;//
        sum += *((int*)p + 1);
        printk("%d: %d\n",j,sum);
    }
    unsigned long end = rdcycle();
    printk("%x,cache miss total cycle is %lx\n", sum, end-begin);
    printk("start loop 2\n");
    sum=0;
    int k;
    uint64_t data;
    uint64_t status = 0;
    uint64_t rdbuf_ptr = 0;
    uint64_t addr = 0;
    reg_write8(RESET_PTR,1);
    reg_write8(RESET_PTR,0);
    reg_write64(READ_OFFSET1,Read_Format(1,0,0,0));
    unsigned long  begin2 = rdcycle();
    for(k = 0;k < 32;k++,rdbuf_ptr+=2,addr += 64){
        reg_write64(REQUEST_ADDR,Get_Read_Request(8,rdbuf_ptr,addr,1));
    }
    //for(k = 0;k < 32;k++,rdbuf_ptr+=2,addr += 64){
    //    reg_write64(REQUEST_ADDR,Get_Read_Request(8,rdbuf_ptr,addr,2));
    //}
    //for(k = 0;k < 32;k++,rdbuf_ptr+=2,addr += 64){
    //    reg_write64(REQUEST_ADDR,Get_Read_Request(8,rdbuf_ptr,addr,3));
    //}
    for(rdbuf_ptr = 0,j = 0; j < 1;j++,rdbuf_ptr = 0){
        do{
            //
            status = reg_read64(READ_STATUS1);
            printk("status: %lx\n",status);
        }while(status != 0xffffffff);
        for(k=0;k<32;k++){
            data = reg_read64(READ_DATA1_L);
            sum += (int) data;
            sum += (data >> 32);
            printk("%d: %d\n",k,sum);
            reg_write64(REQUEST_ADDR, Get_ReadF_Request(0,1));
        }
        for(k = 0;k < 32;k++,rdbuf_ptr+=2,addr += 64){
            reg_write64(REQUEST_ADDR,Get_Read_Request(8,rdbuf_ptr,addr,1));
        }
        /*do{
            status = reg_read64(READ_STATUS2);
        }while(status != 0xffffffffffffffff);*/
        /*reg_write64(READ_OFFSET23,Read_Format(2,0,0,0));
        for(k=0;k<32;k++){
            data = reg_read64(READ_DATA23_L);
            sum += (int) data;
            sum += (data >> 32);
            //reg_write64(REQUEST_ADDR, Get_ReadF_Request(0,2));
        }
        for(k = 0;k < 1;k++,rdbuf_ptr+=2,addr += 64){
            reg_write64(REQUEST_ADDR,Get_Read_Request(8,rdbuf_ptr,addr,2));
        }
        *//*do{
            status = reg_read64(READ_STATUS3);
        }while(status != 0xffffffffffffffff);*/
        /*reg_write64(READ_OFFSET23,Read_Format(3,0,0,0));
        for(k=0;k<1;k++){
            data = reg_read64(READ_DATA23_L);
            sum += (int) data;
            sum += (data >> 32);
            reg_write64(REQUEST_ADDR, Get_ReadF_Request(0,3));
        }
        for(k = 0;k < 1;k++,rdbuf_ptr+=2,addr += 64){
            reg_write64(REQUEST_ADDR,Get_Read_Request(8,rdbuf_ptr,addr,3));
        }*/
    }
    do{
            //
            status = reg_read64(READ_STATUS1);
            printk("status: %lx\n",status);
        }while(status != 0xffffffffffffffff);
    for(k=0;k<32;k++){
        data = reg_read64(READ_DATA1_L);
        sum += (int) data;
        sum += (data >> 32);
        printk("%d: %d\n",k,sum);
        reg_write64(REQUEST_ADDR, Get_ReadF_Request(0,1));
    }
    /*reg_write64(READ_OFFSET23,Read_Format(2,0,0,0));
    for(k=0;k<1;k++){
        data = reg_read64(READ_DATA23_L);
        sum += (int) data;
        sum += (data >> 32);
        //reg_write64(REQUEST_ADDR, Get_ReadF_Request(0,2));
    }
    reg_write64(READ_OFFSET23,Read_Format(3,0,0,0));
    for(k=0;k<1;k++){
        data = reg_read64(READ_DATA23_L);
        sum += (int) data;
        sum += (data >> 32);
        reg_write64(REQUEST_ADDR, Get_ReadF_Request(0,3));
    }*/
    unsigned long end2 = rdcycle();
    printk("%x, MMIO total cycle is %lx\n", sum,end2-begin2);
    printk("divid: %f\n",(end-begin)*1.0/(end2-begin2)*1.0);
}

void RandomAccess(){

}
