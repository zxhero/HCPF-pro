package zynq

//import Chisel.{Mem, UInt}
import chisel3._
import chisel3.util._
import freechips.rocketchip.amba.axi4.{AXI4Bundle, AXI4BundleParameters}
import freechips.rocketchip.subsystem.BaseSubsystem
import freechips.rocketchip.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper.{HasRegMap, RegField, RegisterReadIO, RegisterWriteIO}
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util.UIntIsOneOf

case class HCPFParams(address: BigInt, beatBytes: Int, buffNum: Int, tableEntryNum: Int, tableEntryBits: Int)

//case class HCPFBaseParams( buffNum: Int=1024, tableEntryNum: Int=64, tableEntryBits: Int=56)

class Blkbuf(num : Int, w : Int) extends Module {
  val io = IO(new Bundle{
    val wen = Input(Bool())
    val wdata = Input(UInt(w.W))
    val waddr = Input(UInt(log2Ceil(num).W))
    val raddr1 = Input(UInt(log2Ceil(num).W))
    val raddr2 = Input(UInt(log2Ceil(num).W))
    val select = Input(UInt(2.W))
    val rdata1 = Output(UInt(w.W))
    val rdata2 = Output(UInt(w.W))
  })
  //val highbits = Wire(UInt((w/2).W))
  //val lowbits = Wire(UInt(32.W))
  //highbits := Mux(io.select === 3.U, io.wdata(w-1,w/2), io.wdata(w/2-1,0))
  //lowbits := Mux(io.select === 3.U, io.wdata(w/2-1,0), io.wdata(w/2-1,0))
  val buf1 = Mem(num, UInt((w/2).W))
  val dout1 = Wire(UInt(32.W))
  val dout2 = Wire(UInt(32.W))
  //when(io.wen && io.select(1) === 1.U) { buf1(io.waddr) := highbits }
  when(io.wen){
    when(io.waddr(0) === 0.U){
      when(io.select(1) === 1.U){
        buf1(io.waddr) := io.wdata(w-1,w/2)
      }
      when(io.select(0) === 1.U){
        buf0(io.waddr) := io.wdata(w/2-1,0)
      }
    }.elsewhen(io.waddr === 1.U){
      when(io.select(0) === 1.U){
        buf1(io.waddr - 1.U) := io.wdata(w/2-1,0)
      }
      when(io.select(1) === 1.U){
        buf0(io.waddr) := io.wdata(w-1,w/2)
      }
    }
  }
  when(io.raddr1(0) === 1.U){
    dout1 := buf1(io.raddr1 - 1.U)
  }.otherwise{
    dout1 := buf1(io.raddr1)
  }
  when(io.raddr2(0) === 1.U){
    dout2 := buf1(io.raddr2 - 1.U)
  }.otherwise{
    dout2 := buf1(io.raddr2)
  }
  val buf0 = Mem(num, UInt((w/2).W))
 /* when(io.wen && io.select(0) === 1.U) {
    buf0(io.waddr) := io.wdata(w/2-1,0)
  }*/
  val dout3 = buf0(io.raddr1)
  val dout4 = buf0(io.raddr2)
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
    val rdata1 = Output(new ReadTableEntry)
    val rdata2 = Output(new ReadTableEntry)
    val rdata3 = Output(new ReadTableEntry)
  })

  val buf = Mem(params.tableEntryNum, new ReadTableEntry )
  when(io.wen) { buf(io.waddr) := io.wdata }
  io.rdata1 := buf(io.raddr1)
  io.rdata2 := buf(io.raddr2)
  io.rdata3 := buf(io.raddr3)
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
  val CpuOperatePtr = Input(UInt(log2Ceil(params.tableEntryNum).W))
  val rdStatus1 = Output(UInt(64.W))
  val rdStatus2 = Output(UInt(64.W))
  val rdStatus3 = Output(UInt(64.W))
  val rdbuf_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf_wdata = Decoupled(UInt(64.W))
  val rdbuf_wlast = Output(Bool())
}

class ReadStage(params: HCPFParams) extends Module {
  val io = IO(new ReadStageBundle(params))
  val readbuf_wcount = RegInit(0.U(log2Ceil(params.buffNum).W))
  val rd_status1 = RegInit(0.U(64.W))
  val rd_status2 = RegInit(0.U(64.W))
  val rd_status3 = RegInit(0.U(64.W))
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
    first_group := rd_status1((io.CpuOperatePtr + io.axi.r_id(5, 2)) % 64.U) === 0.U(1.W)
    second_group := rd_status1((io.CpuOperatePtr + io.axi.r_id(5, 2) + 16.U) % 64.U) === 0.U(1.W)
    third_group := rd_status1((io.CpuOperatePtr + io.axi.r_id(5, 2) + 32.U) % 64.U) === 0.U(1.W)
    forth_group := rd_status1((io.CpuOperatePtr + io.axi.r_id(5, 2) + 48.U) % 64.U) === 0.U(1.W)
    data_index := io.rdTableEntry1.rdata_ptr
  }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)) {
    first_group := rd_status2((io.CpuOperatePtr + io.axi.r_id(5, 2)) % 64.U) === 0.U(1.W)
    second_group := rd_status2((io.CpuOperatePtr + io.axi.r_id(5, 2) + 16.U) % 64.U) === 0.U(1.W)
    third_group := rd_status2((io.CpuOperatePtr + io.axi.r_id(5, 2) + 32.U) % 64.U) === 0.U(1.W)
    forth_group := rd_status2((io.CpuOperatePtr + io.axi.r_id(5, 2) + 48.U) % 64.U) === 0.U(1.W)
    data_index := io.rdTableEntry2.rdata_ptr
  }.elsewhen(io.axi.r_id(1, 0) === 3.U(2.W)) {
    first_group := rd_status3((io.CpuOperatePtr + io.axi.r_id(5, 2)) % 64.U) === 0.U(1.W)
    second_group := rd_status3((io.CpuOperatePtr + io.axi.r_id(5, 2) + 16.U) % 64.U) === 0.U(1.W)
    third_group := rd_status3((io.CpuOperatePtr + io.axi.r_id(5, 2) + 32.U) % 64.U) === 0.U(1.W)
    forth_group := rd_status3((io.CpuOperatePtr + io.axi.r_id(5, 2) + 48.U) % 64.U) === 0.U(1.W)
    data_index := io.rdTableEntry3.rdata_ptr
  }

  when(first_group === true.B) {
    rd_table_ptr := (io.CpuOperatePtr + io.axi.r_id(5, 2)) % 64.U
  }.elsewhen(second_group === true.B) {
    rd_table_ptr := (io.CpuOperatePtr + io.axi.r_id(5, 2) + 16.U) % 64.U
  }.elsewhen(third_group === true.B) {
    rd_table_ptr := (io.CpuOperatePtr + io.axi.r_id(5, 2) + 32.U) % 64.U
  }.otherwise {
    rd_table_ptr := (io.CpuOperatePtr + io.axi.r_id(5, 2) + 48.U) % 64.U
  }

  io.rdStatus1 := rd_status1
  io.rdStatus2 := rd_status2
  io.rdStatus3 := rd_status3

  when(io.axi.r_last === true.B && io.axi.r_valid === true.B) {
    when(io.axi.r_id(1, 0) === 1.U(2.W)) {
      rd_status1(rd_table_ptr) := 1.U
    }.elsewhen(io.axi.r_id(1, 0) === 2.U(2.W)) {
      rd_status2(rd_table_ptr) := 1.U
    }.elsewhen(io.axi.r_id(1, 0) === 3.U(2.W)) {
      rd_status3(rd_table_ptr) := 1.U
    }
  }

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
    io.axi.ar_id := Cat((io.rdAddrPtr1 - io.CpuOperatePtr) % 16.U(4.W), 1.U(2.W))
    io.axi.ar_len := io.rdAddrEntry1.bits.rsize(9, 3) - 1.U
    io.rdAddrEntry1.ready := io.axi.ar_ready
  }.elsewhen(send_second_table === true.B) {
    io.axi.ar_vaild := io.rdAddrEntry2.valid
    io.axi.ar_addr := Cat(4.U(3.W), io.rdAddrEntry2.bits.raddr)
    io.axi.ar_id := Cat((io.rdAddrPtr1 - io.CpuOperatePtr) % 16.U(4.W), 2.U(2.W))
    io.axi.ar_len := io.rdAddrEntry2.bits.rsize(9, 3) - 1.U
    io.rdAddrEntry2.ready := io.axi.ar_ready
  }.elsewhen(send_third_table === true.B) {
    io.axi.ar_vaild := io.rdAddrEntry3.valid
    io.axi.ar_addr := Cat(4.U(3.W), io.rdAddrEntry3.bits.raddr)
    io.axi.ar_id := Cat((io.rdAddrPtr1 - io.CpuOperatePtr) % 16.U(4.W), 3.U(2.W))
    io.axi.ar_len := io.rdAddrEntry3.bits.rsize(9, 3) - 1.U
    io.rdAddrEntry3.ready := io.axi.ar_ready
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
  //val b_valid = Input(Bool())
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

class HCPFControllerBundle (params: HCPFParams)extends Bundle{
  //val Request = Flipped(Decoupled(new RWRequest))
  //val newReadAddr = Decoupled(new ReadTableEntry(params))
  //val newReadData = Decoupled(new ReadTableEntry(params))
  //val cpuOperateEntry1 = Output(new ReadTableEntry)
  //val cpuOperateEntry2 = Output(new ReadTableEntry)
  //val cpuOperateEntry3 = Output(new ReadTableEntry)
  //val newWriteAddr = Decoupled(new WriteAddrQueueEntry)
  //val newWriteData = Decoupled(new WriteDataQueueEntry)
  //val rdbuf1_raddr1 = Output(UInt(log2Ceil(params.buffNum).W))
  //val rdbuf1_rdata1 = Input(UInt(64.W))
  val rdbuf1_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf1_wselect = Output(UInt(2.W))
  val rdbuf1_wdata = Decoupled(UInt(64.W))
  /*val rdbuf2_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf2_wselect = Output(UInt(2.W))
  val rdbuf2_wdata = Decoupled(UInt(64.W))
  val rdbuf3_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf3_wselect = Output(UInt(2.W))
  val rdbuf3_wdata = Decoupled(UInt(64.W))*/
  val wtbuf_raddr1 = Output(UInt(log2Ceil(params.buffNum).W))
  val wtbuf_rdata1 = Input(UInt(64.W))
  val wtbuf_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val wtbuf_wselect = Output(UInt(2.W))
  val wtbuf_wdata = Decoupled(UInt(64.W))
  //val wstage_axi = new WriteStageAxi
  //val rstage_axi = new ReadStageAxi
  //val rdStatus1 = Output(UInt(64.W))
  //val rdStatus2 = Output(UInt(64.W))
  //val rdStatus3 = Output(UInt(64.W))
  //val rdata_valid = Output(Bool())
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
  val write_addr_queue = Module(new Queue(new WriteAddrQueueEntry, 128))
  val write_data_queue = Module(new Queue(new WriteDataQueueEntry,128))
  val request_queue = Module(new Queue(new RWRequest, entries = 128))

  request_queue.io.enq <> io.Request
  io.RequestQueueEmpty := (request_queue.io.count === 0.U)
  request_queue.io.deq.ready := io.WriteBackAddr.valid === false.B & write_addr_queue.io.enq.ready
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

/*class HCPFType2Controller (params: HCPFParams) extends  Module{

}*/

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
  val CpuOperatePtr = Output(UInt(log2Ceil(params.tableEntryNum).W))
  val CpuOperateEntry1 = Input(new ReadTableEntry)
  val WriteBackAddr = Decoupled(new WriteAddrQueueEntry)
  val WriteBackData = Decoupled(new WriteDataQueueEntry)
  val RequestQueueEmpty = Output(Bool())
}

class HCPFType3Controller (params: HCPFParams) extends  Module{
  val io = IO(new HCPFType3ControllerBundle(params))
  val cpu_operate_ptr = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val read_finish = Wire(Bool())
  val writebuf_wptr = RegInit(0.U(log2Ceil(params.buffNum)))
  val writebuf_wdata_source_ptr = RegInit(0.U(log2Ceil(params.buffNum)))
  val writebuf_wcount = RegInit(0.U(log2Ceil(params.buffNum).W))
  //val writebuf_wsize = RegInit(0.U(10.W))
  val jump_index = Wire(UInt(log2Ceil(params.tableEntryNum).W))
  val request_queue = Module(new Queue(new RWRequest, entries = 128))
  val idole :: busy :: Nil = Enum(2)
  val wdata_state = RegInit(idole)
  //val change_ptr_state = RegInit(idole)
  val send_request_state = RegInit(idole)
  val global_state = wdata_state === idole && send_request_state === idole
  val write_back_inf = Reg(new WriteBackInformation)

  request_queue.io.enq <> io.Request
  when(request_queue.io.deq.bits.request_type === 3.U ){
    request_queue.io.deq.ready := io.RdBufWdata.ready
  }.elsewhen(read_finish === true.B && io.Request.bits.others(3,2) === 3.U){
    request_queue.io.deq.ready := (send_request_state === idole && last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B) || (wdata_state === idole && io.WriteBackAddr.ready === true.B)
  }.otherwise{
    request_queue.io.deq.ready := true.B
  }
  io.RequestQueueEmpty := request_queue.io.count === 0.U
  //instruction 4
  io.RdBufWdata.valid := request_queue.io.deq.bits.request_type === 3.U
  io.RdBufWdata.bits := request_queue.io.deq.bits.others(32,1)
  io.RdBufWaddr := io.CpuOperateEntry1.rdata_ptr +io.Request.bits.others(42,33)
  io.RdBufWselect := 1.U(2.W)
  //instruction 6 and 7
  val last_data = ((writebuf_wcount + 1.U) * 4.U) === request_queue.io.deq.bits.others(61,52)
  io.WriteBackAddr.valid := send_request_state === busy
  io.WriteBackAddr.bits.wsize := write_back_inf.wsize
  io.WriteBackAddr.bits.waddr := write_back_inf.waddr
  io.WriteBackData.valid := send_request_state === busy
  io.WriteBackData.bits.data := Cat(0.U(22.W),write_back_inf.wbuf_ptr)
  io.WriteBackData.bits.wsize := write_back_inf.wsize
  io.WriteBackData.bits.wtype := 1.U(2.W)
  io.CpuOperatePtr := cpu_operate_ptr
  io.WtBufWaddr := writebuf_wptr
  io.WtBufWselect := 3.U(2.W)
  io.WtBufWdata.valid := read_finish && request_queue.io.deq.bits.others(3,2) === 3.U && wdata_state === busy
  io.WtBufWdata.bits := io.RdBufRdata1
  io.RdBufRaddr1 := writebuf_wdata_source_ptr
  read_finish := request_queue.io.deq.valid === true.B && (request_queue.io.deq.bits.request_type === 0.U)
  when(read_finish === true.B && global_state === true.B){
    cpu_operate_ptr := cpu_operate_ptr + request_queue.io.deq.bits.others(51,48)
  }

  when(io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
    writebuf_wcount := writebuf_wcount + io.WtBufWselect(1) + io.WtBufWselect(0)
  }.elsewhen(last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
    writebuf_wcount := 0.U
  }

  when(read_finish === true.B && io.Request.bits.others(3,2) === 3.U && global_state === true.B){
    write_back_inf.wsize := request_queue.io.deq.bits.others(61,52)
    write_back_inf.wbuf_ptr := request_queue.io.deq.bits.others(23,14)
    write_back_inf.waddr := io.CpuOperateEntry1.raddr + request_queue.io.deq.bits.others(13,4) * 4.U
    writebuf_wptr := request_queue.io.deq.bits.others(23,14)
    writebuf_wdata_source_ptr := io.CpuOperateEntry1.rdata_ptr + request_queue.io.deq.bits.others(13,4)
  }.elsewhen(io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
    writebuf_wptr := writebuf_wptr + io.WtBufWselect(1) + io.WtBufWselect(0)
    writebuf_wdata_source_ptr := writebuf_wdata_source_ptr + io.WtBufWselect(1) + io.WtBufWselect(0)
  }

  when(global_state === true.B && read_finish === true.B && io.Request.bits.others(3,2) === 3.U){
    wdata_state := busy
    send_request_state := busy
  }.elsewhen(wdata_state === busy && last_data === true.B && io.WtBufWdata.valid === true.B && io.WtBufWdata.ready === true.B){
    wdata_state := idole
  }.elsewhen(io.WriteBackAddr.ready === true.B && send_request_state === busy){
    send_request_state := idole
  }
}

class HCPFType4ControllerBundle (params: HCPFParams) extends Bundle{
  val Request = Flipped(Decoupled(new RWRequest))
  val RdBufWaddr = Output(UInt(log2Ceil(params.buffNum).W))
  val RdBufWselect = Output(UInt(2.W))
  val RdBufWdata = Decoupled(UInt(64.W))
  val RStageAxi = new ReadStageAxi
  val RdStatus1 = Output(UInt(64.W))
  val RdStatus2 = Output(UInt(64.W))
  val RdStatus3 = Output(UInt(64.W))
  val CpuOperatePtr = Input(UInt(log2Ceil(params.tableEntryNum).W))
  val CpuOperateEntry1 = Output(new ReadTableEntry)
  val CpuOperateEntry2 = Output(new ReadTableEntry)
  val CpuOperateEntry3 = Output(new ReadTableEntry)
  val ReadTableFinish = Output(Bool())
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
  val read_type1 = io.Request.valid === true.B && io.Request.bits.others(1,0) === 1.U(2.W)
  val read_type2 = io.Request.valid === true.B && io.Request.bits.others(1,0) === 2.U(2.W)
  val read_type3 = io.Request.valid === true.B && io.Request.bits.others(1,0) === 3.U(2.W)
  //instruction 1
  io.RStageAxi <> readstage.io.axi
  io.CpuOperateEntry1 := read_table1.io.rdata3
  io.CpuOperateEntry2 := read_table2.io.rdata3
  io.CpuOperateEntry3 := read_table3.io.rdata3

  read_table1.io.wen := read_type1 === true.B
  read_table1.io.wdata.option := 0.U
  read_table1.io.wdata.raddr := io.Request.bits.others(29,2)
  read_table1.io.wdata.rsize := io.Request.bits.others(61,52)
  read_table1.io.wdata.rdata_ptr := io.Request.bits.others(39,30)
  read_table1.io.waddr := free_entry_ptr1
  read_table1.io.raddr3 := io.CpuOperatePtr
  when(read_type1 === true.B){
    free_entry_ptr1 := free_entry_ptr1 + 1.U
  }

  read_table1.io.wen := read_type2 === true.B
  read_table2.io.wdata.option := 0.U
  read_table2.io.wdata.raddr := io.Request.bits.others(29,2)
  read_table2.io.wdata.rsize := io.Request.bits.others(61,52)
  read_table2.io.wdata.rdata_ptr := io.Request.bits.others(39,30)
  read_table2.io.waddr := free_entry_ptr2
  read_table2.io.raddr3 := io.CpuOperatePtr
  when(read_type2 === true.B){
    free_entry_ptr2 := free_entry_ptr2 + 1.U
  }

  read_table1.io.wen := read_type3 === true.B
  read_table3.io.wdata.option := 0.U
  read_table3.io.wdata.raddr := io.Request.bits.others(29,2)
  read_table3.io.wdata.rsize := io.Request.bits.others(61,52)
  read_table3.io.wdata.rdata_ptr := io.Request.bits.others(39,30)
  read_table3.io.waddr := free_entry_ptr3
  read_table3.io.raddr3 := io.CpuOperatePtr
  when(read_type3 === true.B){
    free_entry_ptr3 := free_entry_ptr3 + 1.U
  }
  /* when(io.Request.valid === true.B && io.Request.bits.request_type === 0.U(2.W) && (io.Request.bits.others(1,0) =/= 0.U)){
     when(io.Request.bits.others(61,52) < (64 / 8).U){
       read_buf_ptr := read_buf_ptr + 1.U
     } .otherwise {
       read_buf_ptr := read_buf_ptr + io.Request.bits.others(61, 52+log2Ceil(64 / 8)) //>> 6)
     }
   }*/

  readstage.io.rdAddrEntry.valid := new_read_addr_ptr =/= free_entry_ptr
  read_table.io.raddr1 := new_read_addr_ptr
  readstage.io.rdAddrEntry.bits := read_table.io.rdata1
  readstage.io.rdDataEntry.valid := new_read_data_ptr =/= free_entry_ptr
  read_table.io.raddr2 := new_read_data_ptr
  readstage.io.rdDataEntry.bits := read_table.io.rdata2

  when(readstage.io.rdAddrEntry.ready === true.B && readstage.io.rdAddrEntry.valid === true.B){
    new_read_addr_ptr := new_read_addr_ptr + 1.U
  }

  when(readstage.io.rdDataEntry.ready === true.B && readstage.io.rdDataEntry.valid === true.B){
    new_read_data_ptr := new_read_data_ptr + 1.U
  }

  read_table.io.raddr3 := cpu_operate_ptr
  io.cpuOperateEntry := read_table.io.rdata3
}

class HCPFController (params: HCPFParams)extends Module {
  val io = IO(new HCPFControllerBundle(params))


  /*val free_entry_ptr1 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val free_entry_ptr2 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val free_entry_ptr3 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val new_read_addr_ptr1 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val new_read_addr_ptr2 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val new_read_addr_ptr3 = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  //val new_read_data_ptr = RegInit(0.U(log2Ceil(params.tableEntryNum).W))

 // val read_buf_ptr = RegInit(0.U(log2Ceil(params.buffNum)))
  val read_table1 = Module(new ReadTable(params))
  val read_table2 = Module(new ReadTable(params))
  val read_table3 = Module(new ReadTable(params))*/

  //val wback_addrqueue_entry = Reg(new WriteAddrQueueEntry)
  //val wback_dataqueue_entry = Reg(new WriteDataQueueEntry)
  //val write_buf_ptr = RegInit(0.U(log2Ceil(params.buffNum)))

  val w_idole :: w_back :: w_new :: Nil = Enum(3)
  val writebuf_wstage = RegInit(w_idole)
  val readbuf_wstage = RegInit(w_idole)
//request decode and reply

  when(io.Request.bits.request_type === 3.U){
    io.Request.ready := Mux(io.Request.bits.others(0) === 1.U, writebuf_wstage === w_idole, readbuf_wstage === w_idole)
  }.otherwise{
    io.Request.ready := true.B
  }
//axi link


//read instructions


  io.rdata_valid := cpu_operate_ptr === new_read_data_ptr
//write read buffer instructions
  when(io.Request.valid === true.B && io.Request.bits.request_type === 3.U && io.Request.bits.others(0) === 0.U && readbuf_wstage === w_idole){
    readbuf_wstage := w_back
  }.elsewhen(readstage.io.rdbuf_wdata.valid === true.B && readbuf_wstage === w_idole){
    readbuf_wstage := w_new
  }.elsewhen(readbuf_wstage === w_new && readstage.io.rdbuf_wlast === true.B){
    readbuf_wstage := w_idole
  }.elsewhen(readbuf_wstage === w_back){
    readbuf_wstage := w_idole
  }

  io.rdbuf_wdata.valid := readbuf_wstage === w_back || readbuf_wstage === w_new
  io.rdbuf_wdata.bits := Mux(readbuf_wstage === w_back, io.Request.bits.others(32,1),readstage.io.rdbuf_wdata.bits)
  io.rdbuf_waddr := Mux(readbuf_wstage === w_back, read_table.io.rdata3.rdata_ptr +io.Request.bits.others(42,34),readstage.io.rdbuf_waddr)
  io.rdbuf_wselect := Mux(readbuf_wstage === w_back, Cat(io.Request.bits.others(33),~io.Request.bits.others(33)),3.U(2.W))
  readstage.io.rdbuf_wdata.ready := io.rdbuf_wdata.ready && readbuf_wstage === w_new
//write write buffer instructions
  when(read_finish === true.B && io.Request.bits.others(3,2) === 3.U && writebuf_wstage === w_idole){
    writebuf_wstage := w_back
  }.elsewhen(io.Request.valid === true.B && io.Request.bits.request_type === 3.U && io.Request.bits.others(0) === 1.U && writebuf_wstage === w_idole){
    writebuf_wstage := w_new
  }.elsewhen(writebuf_wstage === w_back && writebuf_wcount === (writebuf_wsize - (64 / 8).U)){
    writebuf_wstage := w_idole
  }.elsewhen(writebuf_wstage === w_new){
    writebuf_wstage := w_idole
  }

  io.rdbuf_raddr1 := writebuf_wdata_source_addr
  io.wtbuf_wdata.valid := writebuf_wstage === w_back || writebuf_wstage === w_new
  io.wtbuf_wdata.bits := Mux(writebuf_wstage === w_back, io.rdbuf_rdata1, io.Request.bits.others(32,1))
  io.wtbuf_waddr := Mux(readbuf_wstage === w_back, writebuf_waddr, io.Request.bits.others(42,34))
  io.wtbuf_wselect := Mux(readbuf_wstage === w_back, 3.U(2.W), Cat(io.Request.bits.others(33),~io.Request.bits.others(33)))
//write confirm instructions
}

trait HCPFTLBundle extends Bundle {
  val axi = new AXI4Bundle(          //valid as input
    AXI4BundleParameters(
      dataBits = 32,
      addrBits = 10,
      idBits = 4,
      userBits = 0
    ))
  val out = Output(UInt(32.W))
}

trait HCPFTLModule  extends HasRegMap {
  val io: HCPFTLBundle
  implicit val p: Parameters
  def params: HCPFParams
  //def zparams : HCPFBaseParams
  val addr_bits = log2Ceil(params.buffNum)
  //val out
  val base = Module(new HCPFController(params))

  io.axi.ar.valid := base.io.rstage_axi.ar_vaild
  io.axi.aw.bits.prot := 0.U
  io.axi.aw.bits.qos := 0.U
  io.axi.aw.bits.len := base.io.wstage_axi.aw_len
  io.axi.aw.bits.addr := base.io.wstage_axi.aw_addr
  io.axi.aw.bits.cache := 0.U
  io.axi.aw.bits.lock := 0.U
  io.axi.aw.bits.size := base.io.wstage_axi.aw_size
  io.axi.aw.valid := base.io.wstage_axi.aw_vaild
  io.axi.aw.bits.burst := 1.U(2.W)
  io.axi.aw.bits.id := base.io.wstage_axi.aw_id
  io.axi.ar.bits.addr := base.io.rstage_axi.ar_addr
  io.axi.ar.bits.prot := 0.U
  io.axi.ar.bits.cache := 0.U
  io.axi.ar.bits.lock := 0.U
  io.axi.ar.bits.size := base.io.rstage_axi.ar_size
  io.axi.ar.bits.qos := 0.U
  io.axi.ar.bits.burst := 1.U(2.W)    //Incr
  io.axi.ar.bits.id := base.io.rstage_axi.ar_id
  io.axi.ar.bits.len := base.io.rstage_axi.ar_len
  io.axi.w.bits.last := base.io.wstage_axi.w_last
  io.axi.w.bits.data := base.io.wstage_axi.w_data
  io.axi.w.bits.strb := 0.U
  io.axi.w.valid := base.io.wstage_axi.w_vaild
  io.axi.b.ready := base.io.wstage_axi.b_ready
  io.axi.r.ready := base.io.rstage_axi.r_ready

  val read_BUFF = Module(new Blkbuf(params.buffNum, w = 64))
  val write_BUFF = Module(new Blkbuf(params.buffNum, w = 64))
  val read_offset1 = RegInit(0.U(64.W))
  val read_data1 = Wire(UInt(64.W))
  val read_offset2 = RegInit(0.U(64.W))
  val read_data2 = Wire(UInt(64.W))
  val read_offset3 = RegInit(0.U(64.W))
  val read_data3 = Wire(UInt(64.W))
  val RWrequest = Wire(new RegisterWriteIO(UInt(64.W)))

  read_data := Mux(base.io.rdata_valid === true.B,0.U(64.W),read_BUFF.io.rdata2)
  base.io.rdbuf_wdata.ready := true.B
  base.io.Request.valid := RWrequest.request.valid
  base.io.Request.bits.request_type := RWrequest.request.bits(63,62)
  base.io.Request.bits.others := RWrequest.request.bits(61,0)
  base.io.wstage_axi.aw_ready := io.axi.aw.ready
  base.io.wstage_axi.w_ready := io.axi.w.ready
  base.io.rstage_axi.ar_ready := io.axi.ar.ready
  base.io.rdbuf_rdata1 := read_BUFF.io.rdata1
  base.io.wtbuf_rdata1 := write_BUFF.io.rdata1
  base.io.wtbuf_wdata.ready := true.B
  base.io.rstage_axi.r_valid := io.axi.r.valid
  base.io.rstage_axi.r_last := io.axi.r.bits.last
  base.io.rstage_axi.r_data := io.axi.r.bits.data

  read_BUFF.io.raddr1 := base.io.rdbuf_raddr1
  read_BUFF.io.raddr2 := base.io.cpuOperateEntry.rdata_ptr + read_offset(addr_bits-1,0)
  read_BUFF.io.waddr := base.io.rdbuf_waddr
  read_BUFF.io.wen := base.io.rdbuf_wdata.valid
  read_BUFF.io.wdata := base.io.rdbuf_wdata.bits
  read_BUFF.io.select := base.io.rdbuf_wselect

  write_BUFF.io.raddr1 := base.io.wtbuf_raddr1
  write_BUFF.io.raddr2 := 0.U
  write_BUFF.io.waddr := base.io.wtbuf_waddr
  write_BUFF.io.wen := base.io.wtbuf_wdata.valid
  write_BUFF.io.wdata := base.io.wtbuf_wdata.bits
  write_BUFF.io.select := base.io.wtbuf_wselect

  RWrequest.request.ready := base.io.Request.ready
  RWrequest.response.valid := true.B
  RWrequest.response.bits := true.B

  io.out := read_BUFF.io.rdata1

  regmap(
    0x00 -> Seq(
      RegField.w(64, read_offset1)),
    0x8 -> Seq(
      RegField.r(64,read_data1)
    ),
    0x10 -> Seq(
      RegField.r(64,read_offset2)
    ),
    0x18 -> Seq(
      RegField.r(64,read_data2)
    ),
    0x20 -> Seq(
      RegField.r(64,read_offset3)
    ),
    0x28 -> Seq(
      RegField.r(64,read_data3)
    ),
    0x30 -> Seq(
      RegField.w(64,RWrequest)
    ),
    0x38 -> Seq(
      RegField.w(64,base.io.rdStatus1)
    ),
    0x40 -> Seq(
      RegField.w(64,base.io.rdStatus2)
    ),
    0x48 -> Seq(
      RegField.w(64,base.io.rdStatus3)
    )
  )
}

class PWMTL(c: HCPFParams)(implicit p: Parameters)
  extends TLRegisterRouter(
    c.address, "hcpf", Seq("zxhero,hcpf"),
    beatBytes = c.beatBytes, concurrency = 1)(
      new TLRegBundle(c, _) with HCPFTLBundle)(
      new TLRegModule(c, _, _) with HCPFTLModule)

trait HasPeripheryHCPF { this: BaseSubsystem =>
  implicit val p: Parameters

  private val address = 0x2000
  private val portName = "hcpf"

  val hcpf = LazyModule(new PWMTL(
    HCPFParams(address=address, beatBytes = pbus.beatBytes, buffNum=1024, tableEntryNum=64, tableEntryBits=56))(p))

  pbus.toVariableWidthSlave(Some(portName)) { hcpf.node }
}

trait HasPeripheryHCPFModuleImp extends LazyModuleImp {
  implicit val p: Parameters
  val outer: HasPeripheryHCPF
  val hcpfout = IO(outer.hcpf.module.io.axi.cloneType)
  val hcpftest = IO(Output(UInt(32.W)))
  hcpfout <> outer.hcpf.module.io.axi
  hcpftest := outer.hcpf.module.io.out
}
