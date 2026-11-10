"""
Pydantic models for Node data, mirroring the Flutter NodeModel.
"""

from enum import Enum
from pydantic import BaseModel


class NodeArea(str, Enum):
    sumbagut = "sumbagut"
    sumbagteng = "sumbagteng"
    sumbagsel = "sumbagsel"
    jabo = "jabo"
    jabar = "jabar"
    kalimantan = "kalimantan"
    sulawesi = "sulawesi"
    malirja = "malirja"
    testbed = "testbed"


class NodeType(str, Enum):
    standalone = "standalone"
    gwc = "gwc"
    gwu = "gwu"
    pcc = "pcc"
    pcg = "pcg"


class NodeExecutionStatus(str, Enum):
    ready = "ready"
    login = "login"
    check_user = "checkUser"
    load_script = "loadScript"
    validate = "validate"
    commit = "commit"
    done = "done"
    failed = "failed"


class NodeResponse(BaseModel):
    id: str
    name: str
    ip: str
    area: NodeArea
    type: NodeType
    is_online: bool = False
