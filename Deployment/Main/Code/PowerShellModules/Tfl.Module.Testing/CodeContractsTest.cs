﻿/**
 * Copyright 2015-2016 d-fens GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using System.Diagnostics.Contracts;

namespace Tfl.Module.Testing
{
    // this class is used as an example to test CodeContract with code rewriting
    // it must be in an assembly other than where the test runs
    internal class CodeContractsTest
    {
        public int CallingMeWithTrueReturns42ThrowsContractExceptionOtherwise(bool itMustBeTrue)
        {
            Contract.Requires(itMustBeTrue);

            return 42;
        }
    }
}