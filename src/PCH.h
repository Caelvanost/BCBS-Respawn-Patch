#pragma once

#include <RE/Skyrim.h>
#include <SKSE/SKSE.h>
#include <SKSE/Logger.h>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <memory>
#include <string_view>

// CommonLibSSE-NG's generated plugin metadata source uses the standard
// string_view `sv` literal. Make only that literal namespace available to
// every source compiled with this private precompiled header, including the
// generated __BCBSRespawnPatchPlugin.cpp file.
using namespace std::literals::string_view_literals;
