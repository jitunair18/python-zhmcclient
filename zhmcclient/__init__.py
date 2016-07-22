# Copyright 2016 IBM Corp. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
zhmcclient - A pure Python client library for the z Systems HMC Web Services
API.

For documentation, see TODO: Add link to RTD once available.
"""

from __future__ import absolute_import

from ._version import *       # noqa: F401
from ._exceptions import *    # noqa: F401
from ._manager import *       # noqa: F401
from ._resource import *      # noqa: F401
from ._session import *       # noqa: F401
from ._client import *        # noqa: F401
from ._cpc import *           # noqa: F401
from ._lpar import *          # noqa: F401
from ._partition import *     # noqa: F401