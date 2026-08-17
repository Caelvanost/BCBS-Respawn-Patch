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

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    InitLogging();
    SKSE::Init(skse);

    SKSE::log::info("BCBS Respawn Patch native save listener loading");

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
