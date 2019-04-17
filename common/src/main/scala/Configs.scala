package zynq

import chisel3._
import freechips.rocketchip.config.{Config, Parameters}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.devices.tilelink.BootROMParams
import freechips.rocketchip.rocket.{DCacheParams, ICacheParams, MulDivParams, RocketCoreParams}
import freechips.rocketchip.tile.{BuildCore, RocketTileParams, XLen}
import testchipip._
import freechips.rocketchip.diplomacy._

class WithBootROM extends Config((site, here, up) => {
  case BootROMParams => BootROMParams(
    contentFileName = s"../testchipip/bootrom/bootrom.rv${site(XLen)}.img")
})

class WithZynqAdapter extends Config((site, here, up) => {
  case SerialFIFODepth => 16
  case ResetCycles => 10
  case ZynqAdapterBase => BigInt(0x43C00000L)
  case ExtMem => up(ExtMem, site).copy(idBits = 6)
  case ExtIn => up(ExtIn, site).copy(beatBytes = 4, idBits = 12)
  case BlockDeviceKey => BlockDeviceConfig(nTrackers = 2)
  case BlockDeviceFIFODepth => 16
  case NetworkFIFODepth => 16
})

class WithNMediumCores(n: Int) extends Config((site, here, up) => {
  case RocketTilesKey => {
    val medium = RocketTileParams(
      core = RocketCoreParams(fpu = None),
      btb = None,
      dcache = Some(DCacheParams(
        rowBits = site(SystemBusKey).beatBytes*8,
        nSets = 64,
        nWays = 1,
        nTLBEntries = 4,
        nMSHRs = 0,
        blockBytes = site(CacheBlockBytes))),
      icache = Some(ICacheParams(
        rowBits = site(SystemBusKey).beatBytes*8,
        nSets = 64,
        nWays = 1,
        nTLBEntries = 4,
        blockBytes = site(CacheBlockBytes))))
    List.tabulate(n)(i => medium.copy(hartId = i))
  }
})

class AsynBusConfig extends Config(new BaseSubsystemConfig().alter((site,here,up) => {
  // DTS descriptive parameters
  case DTSModel => "freechips,rocketchip-unknown"
  case DTSCompat => Nil
  case DTSTimebase => BigInt(1000000) // 1 MHz
  // External port parameters
  case NExtTopInterrupts => 2
  case ExtMem => MasterPortParams(
    base = x"8000_0000",
    size = x"1000_0000",
    beatBytes = site(MemoryBusKey).beatBytes,
    idBits = 4)
  case ExtBus => MasterPortParams(
    base = x"6000_0000",
    size = x"2000_0000",
    beatBytes = site(MemoryBusKey).beatBytes,
    idBits = 4)
  case PeripheryBusKey => PeripheryBusParams(beatBytes = site(XLen)/8, blockBytes = site(CacheBlockBytes), sbusCrossingType = AsynchronousCrossing(depth = 32))
  case ExtIn  => SlavePortParams(beatBytes = 8, idBits = 8, sourceBits = 4)
}))

class DeepPBusConfig extends Config(new BaseSubsystemConfig().alter((site,here,up) => {
  // DTS descriptive parameters
  case DTSModel => "freechips,rocketchip-unknown"
  case DTSCompat => Nil
  case DTSTimebase => BigInt(1000000) // 1 MHz
  // External port parameters
  case NExtTopInterrupts => 2
  case ExtMem => MasterPortParams(
    base = x"8000_0000",
    size = x"1000_0000",
    beatBytes = site(MemoryBusKey).beatBytes,
    idBits = 4)
  case ExtBus => MasterPortParams(
    base = x"6000_0000",
    size = x"2000_0000",
    beatBytes = site(MemoryBusKey).beatBytes,
    idBits = 4)
  case PeripheryBusKey => PeripheryBusParams(beatBytes = site(XLen)/8, blockBytes = site(CacheBlockBytes), bufferAtomics = BufferParams(32))
  case ExtIn  => SlavePortParams(beatBytes = 8, idBits = 8, sourceBits = 4)
}))
//class WithPWM extends Config((site, here, up) => {})

class ExperimentConfig extends Config(new BaseSubsystemConfig().alter((site,here,up) => {
  // DTS descriptive parameters
  case DTSModel => "freechips,rocketchip-unknown"
  case DTSCompat => Nil
  case DTSTimebase => BigInt(1000000) // 1 MHz
  // External port parameters
  case NExtTopInterrupts => 2
  case ExtMem => MasterPortParams(
    base = x"8000_0000",
    size = x"3000_0000",
    beatBytes = site(MemoryBusKey).beatBytes,
    idBits = 4)
  case ExtBus => MasterPortParams(
    base = x"6000_0000",
    size = x"2000_0000",
    beatBytes = site(MemoryBusKey).beatBytes,
    idBits = 4)
  case ExtIn  => SlavePortParams(beatBytes = 8, idBits = 8, sourceBits = 4)
}))

class WithNBigCoresNMSHR(n: Int) extends Config((site, here, up) => {
  case RocketTilesKey => {
    val big = RocketTileParams(
      core   = RocketCoreParams(mulDiv = Some(MulDivParams(
        mulUnroll = 8,
        mulEarlyOut = true,
        divEarlyOut = true))),
      dcache = Some(DCacheParams(
        rowBits = site(SystemBusKey).beatBits,
        nMSHRs = 4,
        blockBytes = site(CacheBlockBytes))),
      icache = Some(ICacheParams(
        rowBits = site(SystemBusKey).beatBits,
        blockBytes = site(CacheBlockBytes))))
    List.tabulate(n)(i => big.copy(hartId = i))
  }
})

class DefaultConfig extends Config(
  new WithBootROM ++ new freechips.rocketchip.system.DefaultConfig)
class DefaultMediumConfig extends Config(
  new WithBootROM ++ new WithNMediumCores(1) ++
  new freechips.rocketchip.system.BaseConfig)
class DefaultSmallConfig extends Config(
  new WithBootROM ++ new freechips.rocketchip.system.DefaultSmallConfig)
class AsynConfig extends Config(
  new WithBootROM ++ new freechips.rocketchip.subsystem.WithNBigCores(1) ++ new AsynBusConfig
)
class DeepPbusConfig extends Config(
  new WithBootROM ++ new freechips.rocketchip.subsystem.WithNBigCores(1) ++ new DeepPBusConfig
)
class HCPFConfig extends Config(
  new WithBootROM ++ new WithNBigCoresNMSHR(1) ++ new ExperimentConfig
)

class ZynqConfig extends Config(new WithZynqAdapter ++ new DefaultConfig)
class ZynqMediumConfig extends Config(new WithZynqAdapter ++ new DefaultMediumConfig)
class ZynqSmallConfig extends Config(new WithZynqAdapter ++ new DefaultSmallConfig)
class ZynqAsynConfig extends Config(new WithZynqAdapter ++ new AsynConfig)
class ZynqDeepPbusConfig extends Config(new WithZynqAdapter ++ new DeepPbusConfig)
class ZynqHCPFConfig extends Config(new WithZynqAdapter ++ new HCPFConfig )

class ZynqFPGAConfig extends Config(new WithoutTLMonitors ++ new ZynqConfig)
class ZynqMediumFPGAConfig extends Config(new WithoutTLMonitors ++ new ZynqMediumConfig)
class ZynqSmallFPGAConfig extends Config(new WithoutTLMonitors ++ new ZynqSmallConfig)
class ZynqAsynFPGAConfig extends Config(new WithoutTLMonitors ++ new ZynqAsynConfig)
class ZynqDeepPbusFPGAConfig extends Config(new WithoutTLMonitors ++ new ZynqDeepPbusConfig)
class ZynqHCPFFPGAConfig extends Config(new WithoutTLMonitors ++ new ZynqHCPFConfig)
//class ZynqFPGAHCPFConfig extends Config(new WithoutTLMonitors ++ new ZynqConfig ++ WithPWM)