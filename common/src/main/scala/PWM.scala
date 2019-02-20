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

//case class HCPFBaseParams( buffNum: Int=512, tableEntryNum: Int=128, tableEntryBits: Int=56)

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
  val highbits = Wire(UInt((w/2).W))
  //val lowbits = Wire(UInt(32.W))
  highbits := Mux(io.select === 3.U, io.wdata(w-1,w/2), io.wdata(w/2-1,0))
  //lowbits := Mux(io.select === 3.U, io.wdata(w/2-1,0), io.wdata(w/2-1,0))
  val buf1 = Mem(num, UInt((w/2).W))
  when(io.wen && io.select(1) === 1.U) { buf1(io.waddr) := highbits }
  val dout1 = buf1(io.raddr1)
  val dout2 = buf1(io.raddr2)
  val buf0 = Mem(num, UInt((w/2).W))
  when(io.wen && io.select(0) === 1.U) {
    buf0(io.waddr) := io.wdata(w/2-1,0)
  }
  val dout3 = buf0(io.raddr1)
  val dout4 = buf0(io.raddr2)
  io.rdata1 := Cat(dout1,dout3)
  io.rdata2 := Cat(dout2,dout4)
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
  val rtype = UInt(2.W)
  val rsize = UInt(10.W)
  val raddr = UInt(28.W)
  val rdata_ptr = UInt(log2Ceil(512).W)
  val option = UInt(log2Ceil(128).W)
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
  val ar_id = Output(UInt(4.W))
  val ar_len = Output(UInt(8.W))
  val ar_ready = Input(Bool())
  val r_ready = Output(Bool())
  val r_data = Input(UInt(64.W))
  val r_valid = Input(Bool())
  val r_last = Input(Bool())
}

class ReadStageBundle(params: HCPFParams) extends Bundle{
  val axi = new ReadStageAxi
  val rdAddrEntry = Flipped(Decoupled(new ReadTableEntry))
  val rdDataEntry = Flipped(Decoupled(new ReadTableEntry))
  val rdbuf_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf_wdata = Decoupled(UInt(64.W))
  val rdbuf_wlast = Output(Bool())
}

class ReadStage(params: HCPFParams) extends Module{
  val io = IO(new ReadStageBundle(params))
  val readbuf_wcount = RegInit(0.U(log2Ceil(params.buffNum)))

  io.axi.ar_vaild := io.rdAddrEntry.valid
  io.axi.ar_addr := Cat(4.U(3.W),io.rdAddrEntry.bits.raddr)
  io.axi.ar_size := 3.U
  io.axi.ar_id := 1.U
  io.axi.ar_len := io.rdAddrEntry.bits.rsize(9,3) - 1.U
  io.axi.r_ready := io.rdbuf_wdata.ready

  io.rdAddrEntry.ready := io.axi.ar_ready
  io.rdDataEntry.ready := io.axi.r_last && io.axi.r_valid && io.rdbuf_wdata.ready

  when(io.axi.r_last === false.B && io.axi.r_valid === true.B && io.rdbuf_wdata.ready === true.B){
    readbuf_wcount := readbuf_wcount + 1.U
  }.elsewhen(io.axi.r_last === true.B && io.axi.r_valid === true.B && io.rdbuf_wdata.ready === true.B){
    readbuf_wcount := 0.U
  }

  io.rdbuf_waddr := io.rdDataEntry.bits.rdata_ptr + readbuf_wcount
  io.rdbuf_wdata.valid := io.axi.r_valid
  io.rdbuf_wdata.bits := io.axi.r_data
  io.rdbuf_wlast := io.axi.r_last

}

class WriteStageAxi extends Bundle{
  val aw_vaild = Output(Bool())
  val aw_addr = Output(UInt(32.W))
  val aw_size = Output(UInt(3.W))
  val aw_id = Output(UInt(4.W))
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
  val writebuf_rcount = RegInit(0.U(log2Ceil(params.buffNum)))

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

  io.wtbuf_raddr1 := io.wtdata.bits.data(9,1) + writebuf_rcount
  io.axi.w_data := io.wtbuf_rdata1
}

class HCPFControllerBundle (params: HCPFParams)extends Bundle{
  val Request = Flipped(Decoupled(new RWRequest))
  //val newReadAddr = Decoupled(new ReadTableEntry(params))
  //val newReadData = Decoupled(new ReadTableEntry(params))
  val cpuOperateEntry = Output(new ReadTableEntry)
  //val newWriteAddr = Decoupled(new WriteAddrQueueEntry)
  //val newWriteData = Decoupled(new WriteDataQueueEntry)
  val rdbuf_raddr1 = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf_rdata1 = Input(UInt(64.W))
  val rdbuf_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val rdbuf_wselect = Output(UInt(2.W))
  val rdbuf_wdata = Decoupled(UInt(64.W))
  val wtbuf_raddr1 = Output(UInt(log2Ceil(params.buffNum).W))
  val wtbuf_rdata1 = Input(UInt(64.W))
  val wtbuf_waddr = Output(UInt(log2Ceil(params.buffNum).W))
  val wtbuf_wselect = Output(UInt(2.W))
  val wtbuf_wdata = Decoupled(UInt(64.W))
  val wstage_axi = new WriteStageAxi
  val rstage_axi = new ReadStageAxi
  val rdata_valid = Output(Bool())
}

class HCPFController (params: HCPFParams)extends Module {
  val io = IO(new HCPFControllerBundle(params))

  val readstage = Module(new ReadStage(params))
  val free_entry_ptr = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val new_read_addr_ptr = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val new_read_data_ptr = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
  val cpu_operate_ptr = RegInit(0.U(log2Ceil(params.tableEntryNum).W))
 // val read_buf_ptr = RegInit(0.U(log2Ceil(params.buffNum)))
  val read_table = Module(new ReadTable(params))
  val read_finish = Wire(Bool())

  val writestage = Module(new WriteStage(params))
  val write_addr_queue = Module(new Queue(new WriteAddrQueueEntry, 128))
  val write_data_queue = Module(new Queue(new WriteDataQueueEntry,128))
  val writebuf_waddr = RegInit(0.U(log2Ceil(params.buffNum)))
  val writebuf_wdata_source_addr = RegInit(0.U(log2Ceil(params.buffNum)))
  val writebuf_wcount = RegInit(0.U(10.W))
  val writebuf_wsize = RegInit(0.U(10.W))
  val wback_addrqueue_entry = Reg(new WriteAddrQueueEntry)
  val wback_dataqueue_entry = Reg(new WriteDataQueueEntry)
  //val write_buf_ptr = RegInit(0.U(log2Ceil(params.buffNum)))
  val w_idole :: w_back :: w_new :: Nil = Enum(3)
  val writebuf_wstage = RegInit(w_idole)
  val readbuf_wstage = RegInit(w_idole)
  read_finish := (io.Request.valid === true.B) && (io.Request.bits.request_type === 0.U) && (io.Request.bits.others(1,0) === 0.U)
  when(io.Request.bits.request_type === 3.U){
    io.Request.ready := Mux(io.Request.bits.others(0) === 1.U, writebuf_wstage === w_new, readbuf_wstage === w_back)
  }.otherwise{
    io.Request.ready := true.B
  }
//axi link
  io.rstage_axi <> readstage.io.axi
  io.wstage_axi <> writestage.io.axi
//read instructions
  read_table.io.wen := io.Request.valid === true.B && io.Request.bits.request_type === 0.U(2.W) && (io.Request.bits.others(1,0) =/= 0.U)
  read_table.io.wdata.option := 0.U
  read_table.io.wdata.rtype := io.Request.bits.others(1,0)
  read_table.io.wdata.raddr := io.Request.bits.others(29,2)
  read_table.io.wdata.rsize := io.Request.bits.others(61,52)
  read_table.io.wdata.rdata_ptr := io.Request.bits.others(39,31)
  read_table.io.waddr := free_entry_ptr

  when(io.Request.valid === true.B && io.Request.bits.request_type === 0.U(2.W) && (io.Request.bits.others(1,0) =/= 0.U)){
    free_entry_ptr := free_entry_ptr + 1.U
  } .otherwise{
    free_entry_ptr := free_entry_ptr
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

  when(read_finish === true.B){
    cpu_operate_ptr := cpu_operate_ptr + 1.U
  }

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

  when(read_finish === true.B && io.Request.bits.others(3,2) === 3.U && writebuf_wstage === w_idole){

    writebuf_wsize := io.Request.bits.others(13,4)
    wback_addrqueue_entry.waddr := read_table.io.rdata3.raddr
    wback_addrqueue_entry.wsize := io.Request.bits.others(13,4)
    wback_dataqueue_entry.wtype := 1.U(2.W)
    wback_dataqueue_entry.wsize := io.Request.bits.others(13,4)
    wback_dataqueue_entry.data := io.Request.bits.others(23,15)
  }

  when(writebuf_wstage === w_back){
    writebuf_wcount := writebuf_wcount + (64 / 8).U
  }.otherwise{
    writebuf_wcount := 0.U
  }

  when(read_finish === true.B && io.Request.bits.others(3,2) === 3.U && writebuf_wstage === w_idole){
    writebuf_waddr := read_table.io.rdata3.rdata_ptr//io.Request.bits.others(23,15)
    writebuf_wdata_source_addr := read_table.io.rdata3.rdata_ptr
  }.elsewhen(writebuf_wstage === w_back){
    writebuf_waddr := writebuf_waddr + 1.U
    writebuf_wdata_source_addr := writebuf_wdata_source_addr + 1.U
  }

  io.rdbuf_raddr1 := writebuf_wdata_source_addr
  io.wtbuf_wdata.valid := writebuf_wstage === w_back || writebuf_wstage === w_new
  io.wtbuf_wdata.bits := Mux(writebuf_wstage === w_back, io.rdbuf_rdata1, io.Request.bits.others(32,1))
  io.wtbuf_waddr := Mux(readbuf_wstage === w_back, writebuf_waddr, io.Request.bits.others(42,34))
  io.wtbuf_wselect := Mux(readbuf_wstage === w_back, 3.U(2.W), Cat(io.Request.bits.others(33),~io.Request.bits.others(33)))
//write confirm instructions
  when(writebuf_wstage === w_back){
    write_addr_queue.io.enq.bits := wback_addrqueue_entry
    write_data_queue.io.enq.bits := wback_dataqueue_entry
  }.otherwise{
    write_addr_queue.io.enq.bits.waddr := io.Request.bits.others(27,0)
    write_addr_queue.io.enq.bits.wsize := Mux(io.Request.bits.request_type === 1.U, io.Request.bits.others(61,52), io.Request.bits.others(61,60))
    write_data_queue.io.enq.bits.data := Mux(io.Request.bits.request_type === 1.U, io.Request.bits.others(37,29), io.Request.bits.others(59,28))
    write_data_queue.io.enq.bits.wsize := Mux(io.Request.bits.request_type === 1.U, io.Request.bits.others(61,52), io.Request.bits.others(61,60))
    write_data_queue.io.enq.bits.wtype := io.Request.bits.request_type
  }

  write_addr_queue.io.enq.valid := (writebuf_wstage === w_back && writebuf_wcount === (writebuf_wsize - (64 / 8).U)) || (io.Request.valid && (io.Request.bits.request_type === 1.U || io.Request.bits.request_type === 2.U))
  write_data_queue.io.enq.valid := (writebuf_wstage === w_back && writebuf_wcount === (writebuf_wsize - (64 / 8).U)) || (io.Request.valid && (io.Request.bits.request_type === 1.U || io.Request.bits.request_type === 2.U))
  writestage.io.wtaddr <> write_addr_queue.io.deq
  writestage.io.wtdata <> write_data_queue.io.deq
  io.wtbuf_raddr1 := writestage.io.wtbuf_raddr1
  writestage.io.wtbuf_rdata1 := io.wtbuf_rdata1
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
  val write_BUFF = Module(new Blkbuf(params.buffNum, w = 32))
  val read_offset = RegInit(0.U(64.W))
  val read_data = Wire(UInt(64.W))
  read_data := Mux(base.io.rdata_valid === true.B,0.U(64.W),read_BUFF.io.rdata2)
  val RWrequest = Wire(new RegisterWriteIO(UInt(64.W)))

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
  read_BUFF.io.raddr2 := base.io.cpuOperateEntry.rdata_ptr + read_offset(addr_bits-1,1)
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
      RegField.w(64, read_offset)),
    0x8 -> Seq(
      RegField.r(64,read_data)
    ),
    0x10 -> Seq(
      RegField.w(64,RWrequest)
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
    HCPFParams(address=address, beatBytes = pbus.beatBytes, buffNum=512, tableEntryNum=128, tableEntryBits=56))(p))

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
