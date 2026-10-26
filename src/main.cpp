#include "PCH.h"

namespace
{
    constexpr auto kSaveSerialEditorID = "BCBSRP_SaveSerial";

    void InitLogging()
    {
        auto path = SKSE::log::log_directory();
        if (!path) {
            return;
        }

        *path /= "BCBSRespawnPatch.log";

        auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(
            path->string(), true);

        auto logger = std::make_shared<spdlog::logger>(
            "BCBSRespawnPatch", std::move(sink));

        spdlog::set_default_logger(std::move(logger));
        spdlog::set_level(spdlog::level::info);
        spdlog::flush_on(spdlog::level::info);
    }

    void SignalSaveEvent()
    {
        auto* saveSerial = RE::TESForm::LookupByEditorID<RE::TESGlobal>(
            kSaveSerialEditorID);

        if (!saveSerial) {
            SKSE::log::warn(
                "Could not find global {}. BCBSRespawnPatch.esp may be missing or misconfigured.",
                kSaveSerialEditorID);
            return;
        }

        saveSerial->value += 1.0F;
        if (saveSerial->value > 1000000.0F) {
            saveSerial->value = 1.0F;
        }

        SKSE::log::info(
            "Game save event detected; checkpoint signal serial is now {}",
            saveSerial->value);
    }

    void OnSKSEMessage(SKSE::MessagingInterface::Message* message)
    {
        if (!message) {
            return;
        }

        switch (message->type) {
        case SKSE::MessagingInterface::kDataLoaded:
            if (RE::TESForm::LookupByEditorID<RE::TESGlobal>(kSaveSerialEditorID)) {
                SKSE::log::info("BCBS respawn save signal initialized");
            } else {
                SKSE::log::warn(
                    "{} was not found at DataLoaded",
                    kSaveSerialEditorID);
            }
            break;

        case SKSE::MessagingInterface::kSaveGame:
            SignalSaveEvent();
            break;

        default:
            break;
        }
    }
}

// One DLL supports both Skyrim 1.6.x and 1.7.x. The CommonLib fork used by
// this branch reads both Address Library format 2 and format 5.
extern "C" __declspec(dllexport) constinit auto SKSEPlugin_Version = []() {
    SKSE::PluginVersionData version;
    version.PluginVersion(REL::Version{
        BCBS_PLUGIN_VERSION_MAJOR,
        BCBS_PLUGIN_VERSION_MINOR,
        BCBS_PLUGIN_VERSION_PATCH,
        0
    });
    version.PluginName(BCBS_PLUGIN_NAME);
    version.AuthorName(BCBS_PLUGIN_AUTHOR);
    version.UsesAddressLibrary();
    version.UsesAddressLibraryV5();
    version.UsesNoStructs();
    return version;
}();

extern "C" __declspec(dllexport) bool SKSEAPI SKSEPlugin_Query(
    const SKSE::QueryInterface* skse,
    SKSE::PluginInfo* info)
{
    info->infoVersion = SKSE::PluginInfo::kVersion;
    info->name = BCBS_PLUGIN_NAME;
    info->version = BCBS_PLUGIN_VERSION_MAJOR * 10000 +
                    BCBS_PLUGIN_VERSION_MINOR * 100 +
                    BCBS_PLUGIN_VERSION_PATCH;

    if (skse->IsEditor()) {
        return false;
    }

    // Skyrim 1.6.x and 1.7.x are both AE-family runtimes in the universal
    // CommonLib runtime detector.
    return REL::Module::RuntimeFor(skse->RuntimeVersion()) ==
           REL::Module::Runtime::AE;
}

extern "C" __declspec(dllexport) bool SKSEAPI SKSEPlugin_Load(
    const SKSE::LoadInterface* skse)
{
    InitLogging();

    const auto runtime = skse->RuntimeVersion();

    // Check before SKSE::Init so a missing Address Library produces a useful
    // plugin log entry instead of terminating during CommonLib initialization.
    if (REL::Module::FindAddressLibrary().empty()) {
        SKSE::log::error(
            "Address Library for runtime {} was not found. BCBS Respawn Patch is inactive.",
            runtime.string());
        return true;
    }

    SKSE::Init(skse);

    SKSE::log::info(
        "BCBS Respawn Patch native save listener loading on Skyrim {}",
        runtime.string());

    auto* messaging = SKSE::GetMessagingInterface();
    if (!messaging) {
        SKSE::log::critical("SKSE messaging interface is unavailable");
        return false;
    }

    if (!messaging->RegisterListener(OnSKSEMessage)) {
        SKSE::log::critical("Failed to register SKSE messaging listener");
        return false;
    }

    return true;
}
