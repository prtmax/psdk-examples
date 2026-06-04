import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_source(relative_path):
    return (ROOT / relative_path).read_text(encoding="utf-8")


def method_body(source, signature):
    start = source.index(signature)
    brace = source.index("{", start)
    depth = 0
    for index in range(brace, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[brace + 1:index]
    raise AssertionError(f"method not closed: {signature}")


class IosObjectiveCContractsTest(unittest.TestCase):
    def test_report_loop_uses_read_next_report_and_treats_timeout_as_idle(self):
        controller = read_source("EMAPIIOSDemo/EMAPIDemoController.m")
        loop = method_body(controller, "- (void)startReportLoopForPrinter:")

        self.assertIn("readNextReportWithError:", loop)
        self.assertIn("EMAPIErrorTimeout", loop)
        self.assertRegex(loop, r"continue\s*;")
        self.assertIn("handleReport:report", loop)

    def test_report_loop_stops_on_disconnect_and_avoids_report_handler_duplicates(self):
        controller = read_source("EMAPIIOSDemo/EMAPIDemoController.m")
        connect = method_body(controller, "- (void)connectDevice:")
        disconnect = method_body(controller, "- (void)disconnect")

        self.assertIn("startReportLoopForPrinter:", connect)
        self.assertIn("stopReportLoop", disconnect)
        self.assertNotIn("reportHandler =", controller)

    def test_report_updates_are_dispatched_to_main_thread(self):
        controller = read_source("EMAPIIOSDemo/EMAPIDemoController.m")
        handle_report = method_body(controller, "- (void)handleReport:(id)report fromGeneration:")

        self.assertIn("NSThread.isMainThread", handle_report)
        self.assertIn("dispatch_get_main_queue()", handle_report)

    def test_esc_builder_uses_sdk_builder_in_protocol_order(self):
        builder = read_source("EMAPIIOSDemo/EMAPIDemoESCBuilder.m")
        sdk_branch = builder.split("#else", 1)[0]
        command_chain = sdk_branch[sdk_branch.index("command.BasicESC"):]

        expected = [
            ".wakeup()",
            ".enable()",
            ".paperType(",
            ".thickness(",
            ".image(",
            ".position()",
            ".stopJob()",
        ]
        last_index = -1
        for token in expected:
            index = command_chain.find(token)
            self.assertGreater(index, last_index, token)
            last_index = index
        self.assertIn(".mode((Mode)printMode)", sdk_branch)
        self.assertIn("[command.command binary]", sdk_branch)

    def test_fallback_esc_bytes_include_position_only_for_non_continuous_paper(self):
        builder = read_source("EMAPIIOSDemo/EMAPIDemoESCBuilder.m")
        fallback_branch = builder.split("#else", 1)[1]

        self.assertIn("paperType != EMAPIDemoEscPaperTypeContinuous", fallback_branch)
        self.assertIn("0x1D, 0x0C", fallback_branch)
        self.assertIn("0x10, 0xFF, 0xFE, 0x45", fallback_branch)

    def test_print_mode_copy_uses_bicolor(self):
        view_controller = read_source("EMAPIIOSDemo/EMAPIDemoViewController.m")

        self.assertIn('@"双色"', view_controller)
        self.assertNotIn('@"双重"', view_controller)


if __name__ == "__main__":
    unittest.main()
