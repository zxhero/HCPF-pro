package zynq

import chisel3.{RegInit, _}
import chisel3.util._
import freechips.rocketchip.amba.axi4.{AXI4Bundle, AXI4BundleParameters}
import freechips.rocketchip.subsystem.BaseSubsystem
import freechips.rocketchip.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper.{HasRegMap, RegField, RegisterReadIO, RegisterWriteIO}
import freechips.rocketchip.tilelink._

case class HCPFParams(address: BigInt, beatBytes: Int, buffNum: Int, tableEntryNum: Int, tableEntryBits: Int)

//case class HCPFBaseParams( buffNum: Int=1024, tableEntryNum: Int=64, tableEntryBits: Int=56)

class Blkbuf(num : Int, w : Int) extends Module {
    val io = IO(new Bundle{
        val wen = Input(Bool())
        val wdata = Input(UInt(w.W))
        val waddr = Input(UInt((log2Ceil(num)).W))
        val raddr1 = Input(UInt(log2Ceil(num).W))
        val raddr2 = Input(UInt(log2Ceil(num).W))
        val raddr3 = Input(UInt(log2Ceil(num).W))
        val raddr4 = Input(UInt(log2Ceil(num).W))
        val raddr5 = Input(UInt(log2Ceil(num).W))
        val raddr6 = Input(UInt(log2Ceil(num).W))
        val raddr7 = Input(UInt(log2Ceil(num).W))
        val select = Input(UInt(2.W))
        val rdata1 = Output(UInt(w.W))
        val rdata2 = Output(UInt(w.W))
        val rdata3 = Output(UInt(w.W))
        val rdata4 = Output(UInt(w.W))
        val rdata5 = Output(UInt(w.W))
        val rdata6 = Output(UInt(w.W))
        val rdata7 = Output(UInt(w.W))
    })
    val buf0 = Mem(num/2, UInt((w/2).W))
    val buf1 = Mem(num/2, UInt((w/2).W))

    when(io.wen === true.B){
        when(io.waddr(0) === 0.U){
            when(io.select(1) === 1.U){
                buf1(io.waddr(log2Ceil(num)-1,1)) := io.wdata(w-1,w/2)
            }
        }.elsewhen(io.waddr(0) === 1.U){
            when(io.select(0) === 1.U){
                buf1(io.waddr(log2Ceil(num)-1,1)) := io.wdata(w/2-1,0)
            }
        }
    }
    when(io.wen === true.B){
        when(io.waddr(0) === 0.U && io.select(0) === 1.U){
            buf0(io.waddr(log2Ceil(num)-1,1)) := io.wdata(w/2-1,0)
        }.elsewhen(io.waddr(0) === 1.U && io.select(1) === 1.U){
            buf0(io.waddr(log2Ceil(num)-1,1)) := io.wdata(w-1,w/2)
        }
    }
    val  dout1 = buf1(io.raddr1(log2Ceil(num)-1,1))
    val  dout2 = buf1(io.raddr2(log2Ceil(num)-1,1))
    val  dout5 = buf1(io.raddr3(log2Ceil(num)-1,1))
    val  dout7 = buf1(io.raddr4(log2Ceil(num)-1,1))
    val dout9 = buf1(io.raddr5(log2Ceil(num)-1,1))
    val dout11 = buf1(io.raddr6(log2Ceil(num)-1,1))
    val dout13 = buf1(io.raddr7(log2Ceil(num)-1,1))
    val dout3 = buf0((io.raddr1 + 1.U)(log2Ceil(num)-1,1))
    val dout4 = buf0((io.raddr2 + 1.U)(log2Ceil(num)-1,1))
    val dout6 = buf0((io.raddr3 + 1.U)(log2Ceil(num)-1,1))
    val dout8 = buf0((io.raddr4 + 1.U)(log2Ceil(num) - 1,1))
    val dout10 = buf0(io.raddr5(log2Ceil(num)-1,1))
    val dout12 = buf0(io.raddr6(log2Ceil(num)-1,1))
    val dout14 = buf0(io.raddr7(log2Ceil(num)-1,1))
    when(io.raddr1(0) === 1.U){
        io.rdata1 := Cat(dout3,dout1)
    }.otherwise{
        io.rdata1 := Cat(dout1,dout3)
    }

    when(io.raddr2(0) === 1.U){
        io.rdata2 := Cat(dout4,dout2)
    }.otherwise{
        io.rdata2 := Cat(dout2,dout4)
    }

    when(io.raddr3(0) === 1.U){
        io.rdata3 := Cat(dout6,dout5)
    }.otherwise{
        io.rdata3 := Cat(dout5,dout6)
    }

    when(io.raddr4(0) === 1.U){
        io.rdata4 := Cat(dout8,dout7)
    }.otherwise{
        io.rdata4 := Cat(dout7,dout8)
    }

    when(io.raddr5(0) === 1.U){
        io.rdata5 := Cat(dout10,dout9)
    }.otherwise{
        io.rdata5 := Cat(dout9,dout10)
    }

    when(io.raddr6(0) === 1.U){
        io.rdata6 := Cat(dout12,dout11)
    }.otherwise{
        io.rdata6 := Cat(dout11,dout12)
    }

    when(io.raddr7(0) === 1.U){
        io.rdata7 := Cat(dout14,dout13)
    }.otherwise{
        io.rdata7 := Cat(dout13,dout14)
    }
}

class RWRequest extends Bundle{
    val request_type = UInt(2.W)
    val others = UInt(62.W)
}

class WriteAddrQueueEntry extends Bundle{
    val waddr = UInt(28.W)
    val wsize = UInt(10.W)
}

class WriteDataQueueEntry extends Bundle{
    val wtype = UInt(2.W)
    val wsize = UInt(10.W)
    val data = UInt(32.W)
}

class ReadTableEntry extends Bundle{
    val rsize = UInt(10.W)
    val raddr = UInt(28.W)
    val rdata_ptr = UInt(log2Ceil(1024).W)
    val option = UInt(log2Ceil(64).W)
}

class ReadTable (params: HCPFParams) extends Module{
    val io = IO(new Bundle{
        val wen = Input(Bool())
        val wdata = Input(new ReadTableEntry)
        val waddr = Input(UInt(log2Ceil(params.tableEntryNum).W))
        val raddr1 = Input(UInt(log2Ceil(params.tableEntryNum).W))
        val raddr2 = Input(UInt(log2Ceil(params.tableEntryNum).W))
        val raddr3 = Input(UInt(log2Ceil(params.tableEntryNum).W))
        val raddr4 = Input(UInt(log2Ceil(params.tableEntryNum).W))
        val rdata1 = Output(new ReadTableEntry)
        val rdata2 = Output(new ReadTableEntry)
        val rdata3 = Output(new ReadTableEntry)
        val rdata4 = Output(new ReadTableEntry)
    })

    val buf = Mem(params.tableEntryNum, new ReadTableEntry )
    when(io.wen) { buf(io.waddr) := io.wdata }
    io.rdata1 := buf(io.raddr1)
    io.rdata2 := buf(io.raddr2)
    io.rdata3 := buf(io.raddr3)
    io.rdata4 := buf(io.raddr4)
}

class ReadStageAxi extends Bundle{
    val ar_vaild = Output(Bool())
    val ar_addr = Output(UInt(32.W))
    val ar_size = Output(UInt(3.W))
    val ar_id = Output(UInt(6.W))
    val ar_len = Output(UInt(8.W))
    val ar_ready = Input(Bool())
    val r_ready = Output(Bool())
    val r_data = Input(UInt(64.W))
    val r_valid = Input(Bool())
    val r_last = Input(Bool())
    val r_id = Input(UInt(6.W))
}

class ReadStageBundle(params: HCPFParams) extends Bundle{
    val axi = new ReadStageAxi
    val rdAddrEntry1 = Flipped(Decoupled(new ReadTableEntry))
    val rdAddrEntry2 = Flipped(Decoupled(new ReadTableEntry))
    val rdAddrEntry3 = Flipped(Decoupled(new ReadTableEntry))
    val rdAddrPtr1 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val rdAddrPtr2 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val rdAddrPtr3 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val rdTablePtr = Output(UInt(log2Ceil(params.tableEntryNum).W))
    val rdTableEntry1 = Input(new ReadTableEntry)
    val rdTableEntry2 = Input(new ReadTableEntry)
    val rdTableEntry3 = Input(new ReadTableEntry)
    val CpuOperatePtr1 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperatePtr2 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperatePtr3 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val rdStatus1 = Output(UInt(64.W))//Output(Vec(64,Bool()))
    val rdStatus2 = Output(UInt(64.W))//Output(Vec(64,Bool()))
    val rdStatus3 = Output(UInt(64.W))//Output(Vec(64,Bool()))
    val StatusReset1 = Input(Bool())
    val StatusReset2 = Input(Bool())
    val StatusReset3 = Input(Bool())
    val FreeEntryPtr1 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val FreeEntryPtr2 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val FreeEntryPtr3 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val rdbuf_waddr = Output(UInt(log2Ceil(params.buffNum).W))
    val rdbuf_wdata = Decoupled(UInt(64.W))
    val rdbuf_wlast = Output(Bool())
}

class ReadStage(params: HCPFParams) extends Module {
    val io = IO(new ReadStageBundle(params))
    val readbuf_wcount = RegInit(0.U(log2Ceil(params.buffNum).W))
    val rd_status1 = RegInit(Vec(Seq.fill(64)(0.U(1.W))))//Reg(init = Vec(Seq.fill(64)(0.U(1.W))))
    val rd_status2 = RegInit(Vec(Seq.fill(64)(0.U(1.W))))//Reg(init = Vec(Seq.fill(64)(UInt(0,1.W))))
    val rd_status3 = RegInit(Vec(Seq.fill(64)(0.U(1.W))))//Reg(init = Vec(Seq.fill(64)(UInt(0,1.W))))
    val round = RegInit(0.U(2.W))
    val data_index = Wire(UInt(log2Ceil(params.buffNum).W))
    val first_group = Wire(Bool())
    val second_group = Wire(Bool())
    val third_group = Wire(Bool())
    val forth_group = Wire(Bool())
    val rd_table_ptr = Wire(UInt(log2Ceil(params.tableEntryNum).W))
    //data channel
    io.rdTablePtr := rd_table_ptr
    when(io.axi.r_id(1, 0) === 1.U(2.W)) {
        first_group := rd_status1((io.CpuOperatePtr1 + io.axi.r_id(5, 2)) % 64.U) === 0.U(1.W)
        second_group := rd_status1((io.CpuOperatePtr1 + io.axi.r_id(5, 2) + 16.U) % 64.U) === 0.U(1.W)
        third_group := rd_status1((io.CpuOperatePtr1 + io.axi.r_id(5, 2) + 32.U) % 64.U) === 0.U(1.W)
        forth_group := rd_status1((io.CpuOperatePtr1 + io.axi.r_id(5, 2) + 48.U) % 64.U) === 0.U(1.W)
        data_index := io.rdTableEntry1.rdata_ptr
    }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)) {
        first_group := rd_status2((io.CpuOperatePtr2 + io.axi.r_id(5, 2)) % 64.U) === 0.U(1.W)
        second_group := rd_status2((io.CpuOperatePtr2 + io.axi.r_id(5, 2) + 16.U) % 64.U) === 0.U(1.W)
        third_group := rd_status2((io.CpuOperatePtr2 + io.axi.r_id(5, 2) + 32.U) % 64.U) === 0.U(1.W)
        forth_group := rd_status2((io.CpuOperatePtr2 + io.axi.r_id(5, 2) + 48.U) % 64.U) === 0.U(1.W)
        data_index := io.rdTableEntry2.rdata_ptr
    }.otherwise{//.elsewhen(io.axi.r_id(1, 0) === 3.U(2.W)) {
        first_group := rd_status3((io.CpuOperatePtr3 + io.axi.r_id(5, 2)) % 64.U) === 0.U(1.W)
        second_group := rd_status3((io.CpuOperatePtr3 + io.axi.r_id(5, 2) + 16.U) % 64.U) === 0.U(1.W)
        third_group := rd_status3((io.CpuOperatePtr3 + io.axi.r_id(5, 2) + 32.U) % 64.U) === 0.U(1.W)
        forth_group := rd_status3((io.CpuOperatePtr3 + io.axi.r_id(5, 2) + 48.U) % 64.U) === 0.U(1.W)
        data_index := io.rdTableEntry3.rdata_ptr
    }

    when(first_group === true.B) {
        when(io.axi.r_id(1, 0) === 1.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr1 + io.axi.r_id(5, 2)) % 64.U
        }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr2 + io.axi.r_id(5, 2)) % 64.U
        }.otherwise{
            rd_table_ptr := (io.CpuOperatePtr3 + io.axi.r_id(5, 2)) % 64.U
        }
    }.elsewhen(second_group === true.B) {
        when(io.axi.r_id(1, 0) === 1.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr1 +  io.axi.r_id(5, 2) + 16.U) % 64.U
        }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr2 + io.axi.r_id(5, 2) + 16.U) % 64.U
        }.otherwise{
            rd_table_ptr := (io.CpuOperatePtr3 + io.axi.r_id(5, 2) + 16.U) % 64.U
        }
    }.elsewhen(third_group === true.B) {
        when(io.axi.r_id(1, 0) === 1.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr1 +  io.axi.r_id(5, 2) + 32.U) % 64.U
        }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr2 + io.axi.r_id(5, 2) + 32.U) % 64.U
        }.otherwise{
            rd_table_ptr := (io.CpuOperatePtr3 + io.axi.r_id(5, 2) + 32.U) % 64.U
        }
    }.otherwise {
        when(io.axi.r_id(1, 0) === 1.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr1 +  io.axi.r_id(5, 2) + 48.U) % 64.U
        }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)){
            rd_table_ptr := (io.CpuOperatePtr2 + io.axi.r_id(5, 2) + 48.U) % 64.U
        }.otherwise{
            rd_table_ptr := (io.CpuOperatePtr3 + io.axi.r_id(5, 2) + 48.U) % 64.U
        }
    }

    when(io.StatusReset1 === true.B){
        rd_status1(io.FreeEntryPtr1) := 0.U//false.B//(1.W)
    }
    when(io.axi.r_last === true.B && io.axi.r_valid === true.B && io.axi.r_ready === true.B && io.axi.r_id(1, 0) === 1.U(2.W) ){
        rd_status1(rd_table_ptr) := 1.U
    }
    when(io.StatusReset2 === true.B){
        rd_status2(io.FreeEntryPtr2) := 0.U(1.W)
    }
    when(io.axi.r_last === true.B && io.axi.r_valid === true.B && io.axi.r_ready === true.B && io.axi.r_id(1, 0) === 2.U(2.W) ){
        rd_status2(rd_table_ptr) := 1.U
    }
    when(io.StatusReset3 === true.B){
        rd_status3(io.FreeEntryPtr3) := 0.U(1.W)
    }
    when(io.axi.r_last === true.B && io.axi.r_valid === true.B && io.axi.r_ready === true.B && io.axi.r_id(1, 0) === 3.U(2.W) ){
        rd_status3(rd_table_ptr) := 1.U
    }

    io.rdStatus1 := rd_status1.asUInt()
    io.rdStatus2 := rd_status2.asUInt()
    io.rdStatus3 := rd_status3.asUInt()

    when(io.axi.r_last === false.B && io.axi.r_valid === true.B && io.rdbuf_wdata.ready === true.B) {
        readbuf_wcount := readbuf_wcount + 1.U
    }.elsewhen(io.axi.r_last === true.B && io.axi.r_valid === true.B && io.rdbuf_wdata.ready === true.B) {
        readbuf_wcount := 0.U
    }

    io.rdbuf_waddr := data_index + 2.U * readbuf_wcount
    io.rdbuf_wdata.valid := io.axi.r_valid
    io.rdbuf_wdata.bits := io.axi.r_data
    io.rdbuf_wlast := io.axi.r_last
    io.axi.r_ready := io.rdbuf_wdata.ready
    //address channel
    val send_first_table = Wire(Bool())
    val send_second_table = Wire(Bool())
    val send_third_table = Wire(Bool())

    send_first_table := (round === 0.U(2.W) && io.rdAddrEntry1.valid === true.B) || (round === 1.U(2.W) && io.rdAddrEntry2.valid === false.B && io.rdAddrEntry3.valid === false.B && io.rdAddrEntry1.valid === true.B) || (round === 2.U(2.W) && io.rdAddrEntry3.valid === false.B && io.rdAddrEntry1.valid === true.B) //true.B
    send_second_table := (round === 0.U(2.W) && io.rdAddrEntry1.valid === false.B && io.rdAddrEntry2.valid === true.B) || (round === 1.U(2.W) && io.rdAddrEntry2.valid === true.B) || (round === 2.U(2.W) && io.rdAddrEntry3.valid === false.B && io.rdAddrEntry1.valid === false.B && io.rdAddrEntry2.valid === true.B)
    send_third_table := (round === 0.U(2.W) && io.rdAddrEntry1.valid === false.B && io.rdAddrEntry2.valid === false.B && io.rdAddrEntry3.valid === true.B) || (round === 1.U(2.W) && io.rdAddrEntry2.valid === false.B && io.rdAddrEntry3.valid === true.B) || (round === 2.U(2.W) && io.rdAddrEntry3.valid === true.B)

    when(send_first_table === true.B) {
        io.axi.ar_vaild := io.rdAddrEntry1.valid
        io.axi.ar_addr := Cat(4.U(3.W), io.rdAddrEntry1.bits.raddr)
        io.axi.ar_id := Cat((io.rdAddrPtr1 - io.CpuOperatePtr1) % 16.U(6.W), 1.U(2.W))
        io.axi.ar_len := io.rdAddrEntry1.bits.rsize(9, 3) - 1.U
        io.rdAddrEntry1.ready := io.axi.ar_ready
        io.rdAddrEntry2.ready := false.B
        io.rdAddrEntry3.ready := false.B
    }.elsewhen(send_second_table === true.B) {
        io.axi.ar_vaild := io.rdAddrEntry2.valid
        io.axi.ar_addr := Cat(4.U(3.W), io.rdAddrEntry2.bits.raddr)
        io.axi.ar_id := Cat((io.rdAddrPtr2 - io.CpuOperatePtr2) % 16.U(6.W), 2.U(2.W))
        io.axi.ar_len := io.rdAddrEntry2.bits.rsize(9, 3) - 1.U
        io.rdAddrEntry1.ready := false.B
        io.rdAddrEntry2.ready := io.axi.ar_ready
        io.rdAddrEntry3.ready := false.B
    }.elsewhen(send_third_table === true.B) {
        io.axi.ar_vaild := io.rdAddrEntry3.valid
        io.axi.ar_addr := Cat(4.U(3.W), io.rdAddrEntry3.bits.raddr)
        io.axi.ar_id := Cat((io.rdAddrPtr3 - io.CpuOperatePtr3) % 16.U(6.W), 3.U(2.W))
        io.axi.ar_len := io.rdAddrEntry3.bits.rsize(9, 3) - 1.U
        io.rdAddrEntry1.ready := false.B
        io.rdAddrEntry2.ready := false.B
        io.rdAddrEntry3.ready := io.axi.ar_ready
    }.otherwise{
        io.axi.ar_vaild := false.B
        io.axi.ar_addr := 0.U
        io.axi.ar_id := 0.U
        io.axi.ar_len := 0.U
        io.rdAddrEntry1.ready := false.B
        io.rdAddrEntry2.ready := false.B
        io.rdAddrEntry3.ready := false.B

    }
    io.axi.ar_size := 3.U
}

class WriteStageAxi extends Bundle{
    val aw_vaild = Output(Bool())
    val aw_addr = Output(UInt(32.W))
    val aw_size = Output(UInt(3.W))
    val aw_id = Output(UInt(6.W))
    val aw_len = Output(UInt(8.W))
    val aw_ready = Input(Bool())
    val w_vaild = Output(Bool())
    val w_last = Output(Bool())
    val w_data = Output(UInt(64.W))
    val w_ready = Input(Bool())
    val w_strb = Output(UInt(8.W))
    val b_ready = Output(Bool())
}

class WriteStageBundle(params: HCPFParams) extends Bundle{
    val axi = new WriteStageAxi
    val wtaddr = Flipped(Decoupled(new WriteAddrQueueEntry))
    val wtdata = Flipped(Decoupled(new WriteDataQueueEntry))
    val wtbuf_raddr1 = Output(UInt(log2Ceil(params.buffNum).W))
    val wtbuf_rdata1 = Input(UInt(64.W))
}

class WriteStage(params: HCPFParams) extends Module{
    val io = IO(new WriteStageBundle(params))
    val writebuf_rcount = RegInit(0.U(log2Ceil(params.buffNum).W))

    io.axi.aw_vaild := io.wtaddr.valid
    io.axi.aw_addr := Cat(4.U(3.W), io.wtaddr.bits.waddr)
    io.axi.aw_size := 3.U
    io.axi.aw_id := 1.U
    io.axi.aw_len := io.wtaddr.bits.wsize(9,3) - 1.U
    io.axi.w_vaild := io.wtdata.valid
    io.axi.b_ready := true.B
    io.axi.w_last := writebuf_rcount === (io.wtdata.bits.wsize(9,3) - 1.U)
    io.axi.w_strb := 255.U(8.W)

    io.wtaddr.ready := io.axi.aw_ready
    io.wtdata.ready := io.axi.w_last && io.wtdata.valid && io.axi.w_ready

    when(io.axi.w_last === false.B && io.wtdata.valid === true.B && io.axi.w_ready === true.B){
        writebuf_rcount := writebuf_rcount + 1.U
    }.elsewhen(io.axi.w_last === true.B && io.wtdata.valid === true.B && io.axi.w_ready === true.B){
        writebuf_rcount := 0.U
    }

    io.wtbuf_raddr1 := io.wtdata.bits.data(9,0) + 2.U * writebuf_rcount
    io.axi.w_data := io.wtbuf_rdata1
}

class HCPFType1ControllerBundle (params: HCPFParams) extends Bundle{
    val Request = Flipped(Decoupled(new RWRequest))
    val WtBufWaddr = Output(UInt(log2Ceil(params.buffNum).W))
    val WtBufWselect = Output(UInt(2.W))
    val WtBufWdata = Decoupled(UInt(64.W))
    val WtBufRaddr1 = Output(UInt(log2Ceil(params.buffNum).W))
    val WtBufRdata1 = Input(UInt(64.W))
    val WStageAxi = new WriteStageAxi
    val WriteBackAddr = Flipped(Decoupled(new WriteAddrQueueEntry))
    val WriteBackData = Flipped(Decoupled(new WriteDataQueueEntry))
    val RequestQueueEmpty = Output(Bool())
}

class HCPFType1Controller (params: HCPFParams) extends  Module{
    val io = IO(new HCPFType1ControllerBundle(params))
    val writestage = Module(new WriteStage(params))
    val write_addr_queue = Module(new Queue(new WriteAddrQueueEntry, 64))
    val write_data_queue = Module(new Queue(new WriteDataQueueEntry,64))
    val request_queue = Module(new Queue(new RWRequest, entries = 64))

    request_queue.io.enq <> io.Request
    io.RequestQueueEmpty := (request_queue.io.count === 0.U)
    when(request_queue.io.deq.bits.request_type === 1.U(2.W) || request_queue.io.deq.bits.request_type === 2.U){
        request_queue.io.deq.ready := (io.WriteBackAddr.valid === false.B) & write_addr_queue.io.enq.ready
    }.otherwise{
        request_queue.io.deq.ready := io.WtBufWdata.ready
    }
    //instruction 2 and 3
    when(io.WriteBackAddr.valid === true.B){
        write_addr_queue.io.enq <> io.WriteBackAddr
        write_data_queue.io.enq <> io.WriteBackData
    }.otherwise{
        io.WriteBackAddr.ready := false.B
        io.WriteBackData.ready := false.B
        write_addr_queue.io.enq.bits.waddr := request_queue.io.deq.bits.others(27,0)
        write_addr_queue.io.enq.bits.wsize := Mux(request_queue.io.deq.bits.request_type === 1.U, request_queue.io.deq.bits.others(61,52), request_queue.io.deq.bits.others(61,60))
        write_data_queue.io.enq.bits.data := Mux(request_queue.io.deq.bits.request_type === 1.U, request_queue.io.deq.bits.others(37,29), request_queue.io.deq.bits.others(59,28))
        write_data_queue.io.enq.bits.wsize := Mux(request_queue.io.deq.bits.request_type === 1.U, request_queue.io.deq.bits.others(61,52), request_queue.io.deq.bits.others(61,60))
        write_data_queue.io.enq.bits.wtype := request_queue.io.deq.bits.request_type
        write_addr_queue.io.enq.valid := Mux(request_queue.io.deq.bits.request_type === 1.U(2.W) || request_queue.io.deq.bits.request_type === 2.U, request_queue.io.deq.valid, false.B)
        write_data_queue.io.enq.valid := Mux(request_queue.io.deq.bits.request_type === 1.U(2.W) || request_queue.io.deq.bits.request_type === 2.U, request_queue.io.deq.valid, false.B)
    }

    writestage.io.wtaddr <> write_addr_queue.io.deq
    writestage.io.wtdata <> write_data_queue.io.deq
    io.WtBufRaddr1 := writestage.io.wtbuf_raddr1
    writestage.io.wtbuf_rdata1 := io.WtBufRdata1
    io.WStageAxi <> writestage.io.axi
    //instruction 5
    io.WtBufWdata.valid := Mux(request_queue.io.deq.bits.request_type === 3.U, request_queue.io.deq.valid, false.B)
    io.WtBufWdata.bits := Cat(0.U(32.W), request_queue.io.deq.bits.others(32,1))
    io.WtBufWaddr :=  request_queue.io.deq.bits.others(42,33)
    io.WtBufWselect := 1.U(2.W)
}

class WriteBackInformation extends Bundle{
    val wsize = UInt(10.W)
    val wbuf_ptr = UInt(10.W)
    val waddr = UInt(28.W)
}

class HCPFType3ControllerBundle (params: HCPFParams) extends Bundle{
    val Request = Flipped(Decoupled(new RWRequest))
    val WtBufWaddr = Output(UInt(log2Ceil(params.buffNum).W))
    val WtBufWselect = Output(UInt(2.W))
    val WtBufWdata = Decoupled(UInt(64.W))
    val RdBufRaddr1 = Output(UInt(log2Ceil(params.buffNum).W))
    val RdBufRdata1 = Input(UInt(64.W))
    val RdBufWaddr = Output(UInt(log2Ceil(params.buffNum).W))
    val RdBufWselect = Output(UInt(2.W))
    val RdBufWdata = Decoupled(UInt(64.W))
    val CpuOperatePtr1 = Output(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperatePtr2 = Output(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperatePtr3 = Output(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperateEntry1 = Input(new ReadTableEntry)
    val WriteBackAddr = Decoupled(new WriteAddrQueueEntry)
    val WriteBackData = Decoupled(new WriteDataQueueEntry)
    val RequestQueueEmpty = Output(Bool())
    val PtrReset = Input(Bool())
}

class HCPFType3Controller (params: HCPFParams) extends  Module{
    val io = IO(new HCPFType3ControllerBundle(params))
    val cpu_operate_ptr1 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val cpu_operate_ptr2 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val cpu_operate_ptr3 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val read_finish = Wire(Bool())
    val writebuf_wptr = RegInit(0.U(log2Ceil(params.buffNum).W))
    val writebuf_wdata_source_ptr = RegInit(0.U(log2Ceil(params.buffNum).W))
    val writebuf_wcount = RegInit(0.U(log2Ceil(params.buffNum).W))
    val request_queue = Module(new Queue(new RWRequest, entries = 64))
    val idole :: busy :: Nil = Enum(2)
    val wdata_state = RegInit(idole)
    val send_request_state = RegInit(idole)
    val global_state = wdata_state === idole && send_request_state === idole
    val write_back_inf = Reg(new WriteBackInformation)
    val last_data = ((writebuf_wcount + io.WtBufWselect(1) + io.WtBufWselect(0)) * 4.U) === request_queue.io.deq.bits.others(61,52)

    request_queue.io.enq <> io.Request
    when(request_queue.io.deq.bits.request_type === 3.U ){
        request_queue.io.deq.ready := io.RdBufWdata.ready
    }.elsewhen(read_finish === true.B && request_queue.io.deq.bits.others(3,2) === 3.U){
        request_queue.io.deq.ready := global_state === false.B && Cat(send_request_state === idole,io.WriteBackAddr.ready === true.B).do_xorR && Cat(last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B,wdata_state === idole).do_xorR//((send_request_state === idole && last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B) || (wdata_state === idole && io.WriteBackAddr.ready === true.B) || ())
    }.otherwise{
        request_queue.io.deq.ready := true.B
    }
    io.RequestQueueEmpty := request_queue.io.count === 0.U
    //instruction 4
    io.RdBufWdata.valid := request_queue.io.deq.valid === true.B && request_queue.io.deq.bits.request_type === 3.U
    io.RdBufWdata.bits := request_queue.io.deq.bits.others(32,1)
    io.RdBufWaddr := io.CpuOperateEntry1.rdata_ptr +request_queue.io.deq.bits.others(42,33)
    io.RdBufWselect := 1.U(2.W)
    //instruction 6 and 7

    io.WriteBackAddr.valid := send_request_state === busy
    io.WriteBackAddr.bits.wsize := write_back_inf.wsize
    io.WriteBackAddr.bits.waddr := write_back_inf.waddr
    io.WriteBackData.valid := send_request_state === busy
    io.WriteBackData.bits.data := Cat(0.U(22.W),write_back_inf.wbuf_ptr)
    io.WriteBackData.bits.wsize := write_back_inf.wsize
    io.WriteBackData.bits.wtype := 1.U(2.W)
    io.CpuOperatePtr1 := cpu_operate_ptr1
    io.CpuOperatePtr2 := cpu_operate_ptr2
    io.CpuOperatePtr3 := cpu_operate_ptr3
    io.WtBufWaddr := writebuf_wptr
    io.WtBufWselect := 3.U(2.W)
    io.WtBufWdata.valid := read_finish && request_queue.io.deq.bits.others(3,2) === 3.U && wdata_state === busy
    io.WtBufWdata.bits := io.RdBufRdata1
    io.RdBufRaddr1 := writebuf_wdata_source_ptr
    read_finish := request_queue.io.deq.valid === true.B && (request_queue.io.deq.bits.request_type === 0.U)
    when(io.PtrReset === true.B){
        cpu_operate_ptr1 := 0.U
    }.elsewhen(read_finish === true.B && global_state === true.B && request_queue.io.deq.bits.others(45) === 1.U){
        cpu_operate_ptr1 := cpu_operate_ptr1 + request_queue.io.deq.bits.others(51,48) + 1.U
    }
    when(io.PtrReset === true.B){
        cpu_operate_ptr2 := 0.U
    }.elsewhen(read_finish === true.B && global_state === true.B && request_queue.io.deq.bits.others(46) === 1.U){
        cpu_operate_ptr2 := cpu_operate_ptr2 + request_queue.io.deq.bits.others(51,48) + 1.U
    }
    when(io.PtrReset === true.B){
        cpu_operate_ptr3 := 0.U
    }.elsewhen(read_finish === true.B && global_state === true.B && request_queue.io.deq.bits.others(47) === 1.U){
        cpu_operate_ptr3 := cpu_operate_ptr3 + request_queue.io.deq.bits.others(51,48) + 1.U
    }

    when(last_data =/= true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
        writebuf_wcount := writebuf_wcount + io.WtBufWselect(1) + io.WtBufWselect(0)
    }.elsewhen(last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
        writebuf_wcount := 0.U
    }

    when(read_finish === true.B && request_queue.io.deq.bits.others(3,2) === 3.U && global_state === true.B){
        write_back_inf.wsize := request_queue.io.deq.bits.others(61,52)
        write_back_inf.wbuf_ptr := request_queue.io.deq.bits.others(23,14)
        write_back_inf.waddr := io.CpuOperateEntry1.raddr + request_queue.io.deq.bits.others(13,4) * 4.U
        writebuf_wptr := request_queue.io.deq.bits.others(23,14)
        writebuf_wdata_source_ptr := io.CpuOperateEntry1.rdata_ptr + request_queue.io.deq.bits.others(13,4)
    }.elsewhen(io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
        writebuf_wptr := writebuf_wptr + io.WtBufWselect(1) + io.WtBufWselect(0)
        writebuf_wdata_source_ptr := writebuf_wdata_source_ptr + io.WtBufWselect(1) + io.WtBufWselect(0)
    }

    when(global_state === true.B && read_finish === true.B && request_queue.io.deq.bits.others(3,2) === 3.U){
        wdata_state := busy
    }.elsewhen(wdata_state === busy && last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
        wdata_state := idole
    }.otherwise{
        wdata_state := wdata_state
    }

    when(global_state === true.B && read_finish === true.B && request_queue.io.deq.bits.others(3,2) === 3.U){
        send_request_state := busy
    }.elsewhen(io.WriteBackAddr.ready === true.B && send_request_state === busy){
        send_request_state := idole
    }.otherwise{
        send_request_state := send_request_state
    }
}

class HCPFType4ControllerBundle (params: HCPFParams) extends Bundle{
    val Request = Flipped(Decoupled(new RWRequest))
    val RdBufWaddr = Output(UInt(log2Ceil(params.buffNum).W))
    val RdBufWselect = Output(UInt(2.W))
    val RdBufWdata = Decoupled(UInt(64.W))
    val RdBufWlast = Output(Bool())
    val RStageAxi = new ReadStageAxi
    val RdStatus1 = Output(UInt(64.W))//Output(Vec(64,Bool()))
    val RdStatus2 = Output(UInt(64.W))//Output(Vec(64,Bool()))
    val RdStatus3 = Output(UInt(64.W))//Output(Vec(64,Bool()))
    val CpuOperatePtr1 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperatePtr2 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperatePtr3 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuReadOffset1 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuReadOffset2 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuReadOffset3 = Input(UInt(log2Ceil(params.tableEntryNum).W))
    val CpuOperateEntry1 = Output(new ReadTableEntry)
    val CpuOperateEntry2 = Output(new ReadTableEntry)
    val CpuOperateEntry3 = Output(new ReadTableEntry)
    val CpuReadEntry1 = Output(new ReadTableEntry)
    val CpuReadEntry2 = Output(new ReadTableEntry)
    val CpuReadEntry3 = Output(new ReadTableEntry)
    val readbase1 = Input(UInt(28.W))
    val readbase2 = Input(UInt(28.W))
    val readbase3 = Input(UInt(28.W))
    //val ReadTableFinish = Output(Bool())
    val PtrReset = Input(Bool())
}

class HCPFType4Controller (params: HCPFParams) extends  Module{
    val io = IO(new HCPFType4ControllerBundle(params))
    val readstage = Module(new ReadStage(params))
    val free_entry_ptr1 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val free_entry_ptr2 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val free_entry_ptr3 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val new_read_addr_ptr1 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val new_read_addr_ptr2 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val new_read_addr_ptr3 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
    val read_table1 = Module(new ReadTable(params))
    val read_table2 = Module(new ReadTable(params))
    val read_table3 = Module(new ReadTable(params))
    val scatter :: normal :: Nil = Enum(2)
    val controller4_status = RegInit(normal)
    val read_type1 = io.Request.valid === true.B && io.Request.bits.others(1,0) === 1.U(2.W) && controller4_status =/= scatter
    val read_type2 = io.Request.valid === true.B && io.Request.bits.others(1,0) === 2.U(2.W) && controller4_status =/= scatter
    val read_type3 = io.Request.valid === true.B && io.Request.bits.others(1,0) === 3.U(2.W) && controller4_status =/= scatter
    val scatter_type = RegInit(VecInit(Seq(0.U(1.W),0.U(1.W),0.U(1.W))))//io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W) && io.Request.bits.others(3,2) === 1.U(2.W)
    val scatter_index = RegInit(VecInit(Seq(0.U(10.W),0.U(10.W),0.U(10.W),0.U(10.W))))
    val scatter_entry_size = RegInit(0.U(5.W))
    val scatter_read_size = RegInit(0.U(3.W))
    val scatter_sent_count = RegInit(0.U(2.W))//val scatter_type2 = //io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W) && io.Request.bits.others(3,2) === 2.U(2.W)
    val scatter_buff_ptr = RegInit(0.U(10.W))
    //val scatter_type3 = //io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W) && io.Request.bits.others(3,2) === 3.U(2.W)
    val addr_notsent_count1 = RegInit(0.U((log2Ceil(params.tableEntryNum)+1).W))
    val addr_notsent_count2 = RegInit(0.U((log2Ceil(params.tableEntryNum)+1).W))
    val addr_notsent_count3 = RegInit(0.U((log2Ceil(params.tableEntryNum)+1).W))

    io.Request.ready := true.B//controller4_status =/= scatter || (controller4_status === scatter && scatter_sent_count)
    //scatter instruction
    when(io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W)){
        controller4_status := scatter
    }.elsewhen(scatter_sent_count === 3.U){
        controller4_status := normal
    }

    when(io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W)){
        scatter_index := Seq(io.Request.bits.others(61,52),io.Request.bits.others(51,42),io.Request.bits.others(41,32),io.Request.bits.others(31,22))
        scatter_entry_size := io.Request.bits.others(11,7)
        scatter_read_size := io.Request.bits.others(6,4)
        scatter_buff_ptr := io.Request.bits.others(21,12)
    }

    when(io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W) && io.Request.bits.others(3,2) === 1.U(2.W)){
        scatter_type := Seq(1.U(1.W),0.U(1.W),0.U(1.W))
    }.elsewhen(io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W) && io.Request.bits.others(3,2) === 2.U(2.W)){
        scatter_type := Seq(0.U(1.W),1.U(1.W),0.U(1.W))
    }.elsewhen(io.Request.valid === true.B && io.Request.bits.others(1,0) === 0.U(2.W) && io.Request.bits.others(3,2) === 3.U(2.W)){
        scatter_type := Seq(0.U(1.W),0.U(1.W),1.U(1.W))
    }.elsewhen(scatter_sent_count === 3.U){
        scatter_type := Seq(0.U(1.W),0.U(1.W),0.U(1.W))
    }

    when(controller4_status === scatter){
        scatter_sent_count := scatter_sent_count + 1.U
    }
    //instruction 1
    io.RStageAxi <> readstage.io.axi
    io.CpuOperateEntry1 := read_table1.io.rdata3
    io.CpuOperateEntry2 := read_table2.io.rdata4
    io.CpuOperateEntry3 := read_table3.io.rdata4
    io.CpuReadEntry1 := read_table1.io.rdata4
    io.CpuReadEntry2 := read_table2.io.rdata3
    io.CpuReadEntry3 := read_table3.io.rdata3
    io.RdBufWaddr := readstage.io.rdbuf_waddr
    io.RdBufWdata <> readstage.io.rdbuf_wdata
    io.RdBufWselect := 3.U(2.W)
    io.RdBufWlast := readstage.io.rdbuf_wlast
    io.RdStatus1 := readstage.io.rdStatus1
    io.RdStatus2 := readstage.io.rdStatus2
    io.RdStatus3 := readstage.io.rdStatus3
    //io.ReadTableFinish := io.CpuOperatePtr === free_entry_ptr1

    read_table1.io.wen := read_type1 === true.B || (controller4_status === scatter && scatter_type(0) === 1.U)
    when(controller4_status === scatter && scatter_type(0) === 1.U){
        read_table1.io.wdata.option := 0.U
        read_table1.io.wdata.raddr := io.readbase1 + scatter_index(scatter_sent_count) * scatter_entry_size
        read_table1.io.wdata.rsize := scatter_read_size * 4.U(10.W)
        read_table1.io.wdata.rdata_ptr := scatter_buff_ptr + scatter_read_size * scatter_sent_count
    }.otherwise{
        read_table1.io.wdata.option := 0.U
        read_table1.io.wdata.raddr := io.Request.bits.others(29,2)
        read_table1.io.wdata.rsize := io.Request.bits.others(61,52)
        read_table1.io.wdata.rdata_ptr := io.Request.bits.others(39,30)
    }
    read_table1.io.waddr := free_entry_ptr1
    read_table1.io.raddr1 := readstage.io.rdTablePtr
    read_table1.io.raddr2 := new_read_addr_ptr1
    read_table1.io.raddr3 := io.CpuOperatePtr1
    read_table1.io.raddr4 := io.CpuOperatePtr1 + io.CpuReadOffset1
    when(io.PtrReset === true.B){
        free_entry_ptr1 := 0.U
    }.elsewhen(read_type1 === true.B || (controller4_status === scatter && scatter_type(0) === 1.U)){
        free_entry_ptr1 := free_entry_ptr1 + 1.U
    }
    when(io.PtrReset === true.B){
        new_read_addr_ptr1 := 0.U
    }.elsewhen(readstage.io.rdAddrEntry1.ready === true.B && readstage.io.rdAddrEntry1.valid === true.B){
        new_read_addr_ptr1 := new_read_addr_ptr1 + 1.U
    }
    when((read_type1 === true.B || (controller4_status === scatter && scatter_type(0) === 1.U)) && !(readstage.io.rdAddrEntry1.ready === true.B && readstage.io.rdAddrEntry1.valid === true.B)){
        addr_notsent_count1 := addr_notsent_count1 + 1.U
    }.elsewhen(!(read_type1 === true.B || (controller4_status === scatter && scatter_type(0) === 1.U)) && (readstage.io.rdAddrEntry1.ready === true.B && readstage.io.rdAddrEntry1.valid === true.B)){
        addr_notsent_count1 := addr_notsent_count1 - 1.U
    }

    read_table2.io.wen := read_type2 === true.B || (controller4_status === scatter && scatter_type(1) === 1.U)
    when(controller4_status === scatter && scatter_type(1) === 1.U){
        read_table2.io.wdata.option := 0.U
        read_table2.io.wdata.raddr := io.readbase2 + scatter_index(scatter_sent_count) * scatter_entry_size
        read_table2.io.wdata.rsize := scatter_read_size * 4.U(10.W)
        read_table2.io.wdata.rdata_ptr := scatter_buff_ptr + scatter_read_size * scatter_sent_count
    }.otherwise{
        read_table2.io.wdata.option := 0.U
        read_table2.io.wdata.raddr := io.Request.bits.others(29,2)
        read_table2.io.wdata.rsize := io.Request.bits.others(61,52)
        read_table2.io.wdata.rdata_ptr := io.Request.bits.others(39,30)
    }
    read_table2.io.waddr := free_entry_ptr2
    read_table2.io.raddr1 := readstage.io.rdTablePtr
    read_table2.io.raddr2 := new_read_addr_ptr2
    read_table2.io.raddr3 := io.CpuOperatePtr2 + io.CpuReadOffset2
    read_table2.io.raddr4 := io.CpuOperatePtr2
    when(io.PtrReset === true.B){
        free_entry_ptr2 := 0.U
    }.elsewhen(read_type2 === true.B || (controller4_status === scatter && scatter_type(1) === 1.U)){
        free_entry_ptr2 := free_entry_ptr2 + 1.U
    }
    when(io.PtrReset === true.B){
        new_read_addr_ptr2 := 0.U
    }.elsewhen(readstage.io.rdAddrEntry2.ready === true.B && readstage.io.rdAddrEntry2.valid === true.B){
        new_read_addr_ptr2 := new_read_addr_ptr2 + 1.U
    }
    when((read_type2 === true.B || (controller4_status === scatter && scatter_type(1) === 1.U)) && !(readstage.io.rdAddrEntry2.ready === true.B && readstage.io.rdAddrEntry2.valid === true.B)){
        addr_notsent_count2 := addr_notsent_count2 + 1.U
    }.elsewhen(!(read_type2 === true.B || (controller4_status === scatter && scatter_type(1) === 1.U)) && (readstage.io.rdAddrEntry2.ready === true.B && readstage.io.rdAddrEntry2.valid === true.B)){
        addr_notsent_count2 := addr_notsent_count2 - 1.U
    }

    read_table3.io.wen := read_type3 === true.B || (controller4_status === scatter && scatter_type(2) === 1.U)
    when(controller4_status === scatter && scatter_type(2) === 1.U){
        read_table3.io.wdata.option := 0.U
        read_table3.io.wdata.raddr := io.readbase3 + scatter_index(scatter_sent_count) * scatter_entry_size
        read_table3.io.wdata.rsize := scatter_read_size * 4.U(10.W)
        read_table3.io.wdata.rdata_ptr := scatter_buff_ptr + scatter_read_size * scatter_sent_count
    }.otherwise{
        read_table3.io.wdata.option := 0.U
        read_table3.io.wdata.raddr := io.Request.bits.others(29,2)
        read_table3.io.wdata.rsize := io.Request.bits.others(61,52)
        read_table3.io.wdata.rdata_ptr := io.Request.bits.others(39,30)
    }
    read_table3.io.waddr := free_entry_ptr3
    read_table3.io.raddr1 := readstage.io.rdTablePtr
    read_table3.io.raddr2 := new_read_addr_ptr3
    read_table3.io.raddr3 := io.CpuOperatePtr3 + io.CpuReadOffset3
    read_table3.io.raddr4 := io.CpuOperatePtr3
    when(io.PtrReset === true.B){
        free_entry_ptr3 := 0.U
    }.elsewhen(read_type3 === true.B || (controller4_status === scatter && scatter_type(2) === 1.U)){
        free_entry_ptr3 := free_entry_ptr3 + 1.U
    }
    when(io.PtrReset === true.B){
        new_read_addr_ptr3 := 0.U
    }.elsewhen(readstage.io.rdAddrEntry3.ready === true.B && readstage.io.rdAddrEntry3.valid === true.B){
        new_read_addr_ptr3 := new_read_addr_ptr3 + 1.U
    }
    when((read_type3 === true.B || (controller4_status === scatter && scatter_type(2) === 1.U)) && !(readstage.io.rdAddrEntry3.ready === true.B && readstage.io.rdAddrEntry3.valid === true.B)){
        addr_notsent_count3 := addr_notsent_count3 + 1.U
    }.elsewhen(!(read_type3 === true.B || (controller4_status === scatter && scatter_type(2) === 1.U)) && (readstage.io.rdAddrEntry3.ready === true.B && readstage.io.rdAddrEntry3.valid === true.B)){
        addr_notsent_count3 := addr_notsent_count3 - 1.U
    }

    readstage.io.CpuOperatePtr1 := io.CpuOperatePtr1
    readstage.io.CpuOperatePtr2 := io.CpuOperatePtr2
    readstage.io.CpuOperatePtr3 := io.CpuOperatePtr3
    readstage.io.StatusReset1 := read_type1 === true.B || (controller4_status === scatter && scatter_type(0) === 1.U)
    readstage.io.rdAddrEntry1.valid := addr_notsent_count1 =/= 0.U
    readstage.io.rdAddrEntry1.bits := read_table1.io.rdata2
    readstage.io.rdAddrPtr1 := new_read_addr_ptr1
    readstage.io.FreeEntryPtr1 := free_entry_ptr1
    readstage.io.rdTableEntry1 := read_table1.io.rdata1
    readstage.io.StatusReset2 := read_type2 === true.B || (controller4_status === scatter && scatter_type(1) === 1.U)
    readstage.io.rdAddrEntry2.valid := addr_notsent_count2 =/= 0.U
    readstage.io.rdAddrEntry2.bits := read_table2.io.rdata2
    readstage.io.rdAddrPtr2 := new_read_addr_ptr2
    readstage.io.FreeEntryPtr2 := free_entry_ptr2
    readstage.io.rdTableEntry2 := read_table2.io.rdata1
    readstage.io.StatusReset3 := read_type3 === true.B || (controller4_status === scatter && scatter_type(2) === 1.U)
    readstage.io.rdAddrEntry3.valid := addr_notsent_count3 =/= 0.U
    readstage.io.rdAddrEntry3.bits := read_table3.io.rdata2
    readstage.io.rdAddrPtr3 := new_read_addr_ptr3
    readstage.io.FreeEntryPtr3 := free_entry_ptr3
    readstage.io.rdTableEntry3 := read_table3.io.rdata1
}

trait HCPFTLBundle extends Bundle {
    val axi = new AXI4Bundle(          //valid as input
        AXI4BundleParameters(
            dataBits = 64,
            addrBits = 32,
            idBits = 6,
            userBits = 0
        ))
    val out = Output(UInt(32.W))
}

trait HCPFTLModule  extends HasRegMap {
    val io: HCPFTLBundle
    implicit val p: Parameters
    def params: HCPFParams
    val addr_bits = log2Ceil(params.buffNum)
    val read_BUFF = Module(new Blkbuf(params.buffNum, w = 64))
    val write_BUFF = Module(new Blkbuf(params.buffNum, w = 64))
    val controler1 = Module(new HCPFType1Controller(params))
    val controler3 = Module(new HCPFType3Controller(params))
    val controler4 = Module(new HCPFType4Controller(params))
    val read_offset1 = RegInit(0.U(64.W))
    //val read_data1 = Wire(UInt(128.W))
    val read_offset2 = RegInit(0.U(64.W))
    val read_offset3 = RegInit(0.U(64.W))
    //val read_data23 = Wire(UInt(128.W))
    val RWrequest = RegInit(0.U(64.W))//Wire(Flipped(Decoupled(UInt(64.W))))
    val old_RWrequest = RegInit(0.U(64.W))
    val RFrequest = Wire(Flipped(Decoupled(UInt(64.W))))
    val PtrReset = RegInit(false.B)
    val rdbase1 = RegInit(0.U(32.W))
    val rdbase2 = RegInit(0.U(32.W))
    val rdbase3 = RegInit(0.U(32.W))
    //val synchronize_Roffset = RegInit(false.B)
    val new_request = old_RWrequest =/= RWrequest

    io.axi.aw.bits.prot := 0.U
    io.axi.aw.bits.qos := 0.U
    io.axi.aw.bits.len := controler1.io.WStageAxi.aw_len
    io.axi.aw.bits.addr := controler1.io.WStageAxi.aw_addr
    io.axi.aw.bits.cache := 0.U
    io.axi.aw.bits.lock := 0.U
    io.axi.aw.bits.size := controler1.io.WStageAxi.aw_size
    io.axi.aw.valid := controler1.io.WStageAxi.aw_vaild
    io.axi.aw.bits.burst := 1.U(2.W)
    io.axi.aw.bits.id := controler1.io.WStageAxi.aw_id

    io.axi.ar.valid := controler4.io.RStageAxi.ar_vaild
    io.axi.ar.bits.addr := controler4.io.RStageAxi.ar_addr
    io.axi.ar.bits.prot := 0.U
    io.axi.ar.bits.cache := 0.U
    io.axi.ar.bits.lock := 0.U
    io.axi.ar.bits.size := controler4.io.RStageAxi.ar_size
    io.axi.ar.bits.qos := 0.U
    io.axi.ar.bits.burst := 1.U(2.W)    //Incr
    io.axi.ar.bits.id := controler4.io.RStageAxi.ar_id
    io.axi.ar.bits.len := controler4.io.RStageAxi.ar_len

    io.axi.w.bits.last := controler1.io.WStageAxi.w_last
    io.axi.w.bits.data := controler1.io.WStageAxi.w_data
    io.axi.w.bits.strb := controler1.io.WStageAxi.w_strb
    io.axi.w.valid := controler1.io.WStageAxi.w_vaild

    io.axi.b.ready := controler1.io.WStageAxi.b_ready
    io.axi.r.ready := controler4.io.RStageAxi.r_ready

    controler1.io.WStageAxi.aw_ready := io.axi.aw.ready
    controler1.io.WStageAxi.w_ready := io.axi.w.ready
    controler1.io.WriteBackAddr <> controler3.io.WriteBackAddr
    controler1.io.WriteBackData <> controler3.io.WriteBackData
    controler1.io.WtBufWdata.ready := true.B
    controler1.io.WtBufRdata1 := write_BUFF.io.rdata1

    controler3.io.RdBufRdata1 := read_BUFF.io.rdata1
    controler3.io.CpuOperateEntry1 := controler4.io.CpuOperateEntry1
    controler3.io.RdBufWdata.ready := true.B
    controler3.io.WtBufWdata.ready := controler1.io.WtBufWdata.valid =/= true.B
    controler3.io.PtrReset := PtrReset

    controler4.io.RStageAxi.ar_ready := io.axi.ar.ready
    controler4.io.RStageAxi.r_data := io.axi.r.bits.data
    controler4.io.RStageAxi.r_id := io.axi.r.bits.id
    controler4.io.RStageAxi.r_last := io.axi.r.bits.last
    controler4.io.RStageAxi.r_valid := io.axi.r.valid
    controler4.io.CpuOperatePtr1 := controler3.io.CpuOperatePtr1
    controler4.io.CpuOperatePtr2 := controler3.io.CpuOperatePtr2
    controler4.io.CpuOperatePtr3 := controler3.io.CpuOperatePtr3
    controler4.io.RdBufWdata.ready := controler3.io.RdBufWdata.valid =/= true.B
    controler4.io.readbase1 := rdbase1
    controler4.io.readbase2 := rdbase2
    controler4.io.readbase3 := rdbase3
    //when(synchronize_Roffset === false.B){
        controler4.io.CpuReadOffset1 := read_offset1(61,62-log2Ceil(params.tableEntryNum))
        controler4.io.CpuReadOffset2 := read_offset2(61,62-log2Ceil(params.tableEntryNum))
        controler4.io.CpuReadOffset3 := read_offset3(61,62-log2Ceil(params.tableEntryNum))
    /*}.otherwise{
        controler4.io.CpuReadOffset1 := read_offset1(61,62-log2Ceil(params.tableEntryNum))
        controler4.io.CpuReadOffset2 := read_offset1(61,62-log2Ceil(params.tableEntryNum))
        controler4.io.CpuReadOffset3 := read_offset1(61,62-log2Ceil(params.tableEntryNum))
    }*/
    controler4.io.PtrReset := PtrReset

    read_BUFF.io.raddr1 := controler3.io.RdBufRaddr1
    //when(synchronize_Roffset === false.B){
        read_BUFF.io.raddr2 := controler4.io.CpuReadEntry1.rdata_ptr + read_offset1(addr_bits-1,0)
        read_BUFF.io.raddr3 := controler4.io.CpuReadEntry1.rdata_ptr + read_offset1(31+addr_bits, 32)
        read_BUFF.io.raddr4 := controler4.io.CpuReadEntry2.rdata_ptr + read_offset2(addr_bits-1,0)
        read_BUFF.io.raddr5 := controler4.io.CpuReadEntry2.rdata_ptr + read_offset2(31+addr_bits, 32)
        read_BUFF.io.raddr6 := controler4.io.CpuReadEntry3.rdata_ptr + read_offset3(addr_bits-1,0)
        read_BUFF.io.raddr7 := controler4.io.CpuReadEntry3.rdata_ptr + read_offset3(31+addr_bits, 32)
    /*}.otherwise{
        read_BUFF.io.raddr2 := controler4.io.CpuReadEntry1.rdata_ptr + read_offset1(addr_bits-1,0)
        read_BUFF.io.raddr3 := controler4.io.CpuReadEntry1.rdata_ptr + read_offset1(31+addr_bits, 32)
        read_BUFF.io.raddr4 := controler4.io.CpuReadEntry2.rdata_ptr + read_offset1(addr_bits-1,0)
        read_BUFF.io.raddr5 := controler4.io.CpuReadEntry2.rdata_ptr + read_offset1(31+addr_bits, 32)
        read_BUFF.io.raddr6 := controler4.io.CpuReadEntry3.rdata_ptr + read_offset1(addr_bits-1,0)
        read_BUFF.io.raddr7 := controler4.io.CpuReadEntry3.rdata_ptr + read_offset1(31+addr_bits, 32)
    }*/

    when(controler3.io.RdBufWdata.valid === true.B){
        read_BUFF.io.waddr := controler3.io.RdBufWaddr
        read_BUFF.io.wen := controler3.io.RdBufWdata.valid
        read_BUFF.io.wdata := controler3.io.RdBufWdata.bits
        read_BUFF.io.select := controler3.io.RdBufWselect
    }.otherwise{
        read_BUFF.io.waddr := controler4.io.RdBufWaddr
        read_BUFF.io.wen := controler4.io.RdBufWdata.valid
        read_BUFF.io.wdata := controler4.io.RdBufWdata.bits
        read_BUFF.io.select := controler4.io.RdBufWselect
    }

    when(controler1.io.WtBufWdata.valid === true.B){
        write_BUFF.io.waddr := controler1.io.WtBufWaddr
        write_BUFF.io.wen := controler1.io.WtBufWdata.valid
        write_BUFF.io.wdata := controler1.io.WtBufWdata.bits
        write_BUFF.io.select := controler1.io.WtBufWselect
    }.otherwise{
        write_BUFF.io.waddr := controler3.io.WtBufWaddr
        write_BUFF.io.wen := controler3.io.WtBufWdata.valid
        write_BUFF.io.wdata := controler3.io.WtBufWdata.bits
        write_BUFF.io.select := controler3.io.WtBufWselect
    }
    write_BUFF.io.raddr1 := controler1.io.WtBufRaddr1
    write_BUFF.io.raddr2 := 0.U
    write_BUFF.io.raddr3 := 0.U
    write_BUFF.io.raddr4 := 0.U
    write_BUFF.io.raddr5 := 0.U
    write_BUFF.io.raddr6 := 0.U
    write_BUFF.io.raddr7 := 0.U

    controler1.io.Request.bits.request_type := RWrequest(63,62)
    controler1.io.Request.bits.others := RWrequest(61,0)
    when(new_request === true.B && (RWrequest(63,62) === 1.U || RWrequest(63,62) === 2.U || (RWrequest(63,62) === 3.U && RWrequest(0) === 1.U))){
        controler1.io.Request.valid := true.B
    }.otherwise{
        controler1.io.Request.valid := false.B
    }

    when(new_request === true.B && RWrequest(63,62) === 3.U && RWrequest(0) === 0.U){
        controler3.io.Request.bits.request_type := RWrequest(63,62)
        controler3.io.Request.bits.others := RWrequest(61,0)
        controler3.io.Request.valid := true.B
    }.otherwise{
        controler3.io.Request.bits.request_type := RFrequest.bits(63,62)
        controler3.io.Request.bits.others := RFrequest.bits(61,0)
        controler3.io.Request.valid := RFrequest.valid
    }

    controler4.io.Request.bits.request_type := RWrequest(63,62)
    controler4.io.Request.bits.others := RWrequest(61,0)
    when(new_request === true.B && RWrequest(63,62) === 0.U){
        controler4.io.Request.valid := true.B
    }.otherwise{
        controler4.io.Request.valid := false.B
    }
    /*when(RWrequest.bits(63,62) === 0.U && RWrequest.bits(1,0) =/= 0.U(2.W)){
        //RWrequest.request.ready := controler4.io.Request.ready
        controler1.io.Request.valid :=  false.B
        controler3.io.Request.valid :=  false.B
        controler4.io.Request.valid :=  RWrequest.valid

    }.elsewhen(RWrequest.bits(63,62) === 1.U || RWrequest.bits(63,62) === 2.U || (RWrequest.bits(63,62) === 3.U && RWrequest.bits(0) === 1.U)){
        controler1.io.Request.valid :=  RWrequest.valid
        controler3.io.Request.valid :=  false.B
        controler4.io.Request.valid :=false.B
        //RWrequest.request.ready := controler1.io.Request.ready
    }.otherwise{
        controler1.io.Request.valid :=  false.B
        controler3.io.Request.valid :=  RWrequest.valid
        controler4.io.Request.valid :=  false.B
        //RWrequest.request.ready := controler3.io.Request.ready
    }*/
    //RWrequest.response.valid := true.B
    //RWrequest.response.bits := true.B
    //RWrequest.ready := true.B

    when(new_request === true.B){
        old_RWrequest := RWrequest
    }.elsewhen(PtrReset === true.B){
        old_RWrequest := 0.U
    }
    RFrequest.ready := true.B
    io.out := read_BUFF.io.rdata1

    regmap(
        0x00 -> Seq(
            RegField.w(64, read_offset1)),
        0x8 -> Seq(
            RegField.r(64,read_BUFF.io.rdata2)
        ),
        0x10 -> Seq(
            RegField.r(64,read_BUFF.io.rdata3)
        ),
        0x18 -> Seq(
            RegField.w(64,read_offset2)
        ),
        0x20 -> Seq(
            RegField.r(64,read_BUFF.io.rdata4)
        ),
        0x28 -> Seq(
            RegField.r(64,read_BUFF.io.rdata5 )
        ),
        0x30 -> Seq(
            RegField.w(64,RWrequest)
        ),
        0x38 -> Seq(
            RegField.r(64,controler4.io.RdStatus1)
        ),
        0x40 -> Seq(
            RegField.r(64,controler4.io.RdStatus2)
        ),
        0x48 -> Seq(
            RegField.r(64,controler4.io.RdStatus3)
        ),
        //0x50 -> Seq(
        //    RegField.r(1,controler1.io.RequestQueueEmpty)
        //),
        //0x51 -> Seq(
        //    RegField.r(1,controler3.io.RequestQueueEmpty)
       // ),
        //0x52 -> Seq(
        //  RegField.r(1,controler4.io.ReadTableFinish)
        //),
        //0x50 -> Seq(
         //   RegField.w(1,synchronize_Roffset)
        //),
        0x54 -> Seq(
            RegField.w(1,PtrReset)
        ),
        0x58 -> Seq(
            RegField.w(64,read_offset3)
        ),
        0x60 -> Seq(
            RegField.r(64,read_BUFF.io.rdata6)
        ),
        0x68 -> Seq(
            RegField.r(64,read_BUFF.io.rdata7)
        ),
        0x70 -> Seq(
            RegField.w(64, RFrequest)
        ),
        0x78 -> Seq(
            RegField.w(32,rdbase1)
        ),
        0x7c -> Seq(
            RegField.w(32,rdbase2)
        ),
        0x80 -> Seq(
            RegField.w(32,rdbase3)
        )
    )
}

class PWMTL(c: HCPFParams)(implicit p: Parameters)
  extends TLRegisterRouter(
      c.address, "hcpf", Seq("zxhero,hcpf"),
      beatBytes = c.beatBytes, concurrency = 0)(
      new TLRegBundle(c, _) with HCPFTLBundle)(
      new TLRegModule(c, _, _) with HCPFTLModule)

trait HasPeripheryHCPF { this: BaseSubsystem =>
    implicit val p: Parameters

    private val address = 0x2000
    private val portName = "hcpf"

    val hcpf = LazyModule(new PWMTL(
        HCPFParams(address=address, beatBytes = pbus.beatBytes, buffNum=1024, tableEntryNum=64, tableEntryBits=56))(p))

    sbus.toVariableWidthSlave(Some(portName),buffer = BufferParams.none) { hcpf.node }
}

trait HasPeripheryHCPFModuleImp extends LazyModuleImp {
    implicit val p: Parameters
    val outer: HasPeripheryHCPF
    val hcpfout = IO(outer.hcpf.module.io.axi.cloneType)
    val hcpftest = IO(Output(UInt(32.W)))
    hcpfout <> outer.hcpf.module.io.axi
    hcpftest := outer.hcpf.module.io.out
}