package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.io.IOException;
import java.util.Locale;
import java.util.Map;

/**
 * 奶蛙桌宠启动接口。
 *
 * 浏览器出于安全限制不能直接启动本机 exe，所以由后端按固定路径启动；
 * 前端打开页面时调用一次即可。重复调用不会开出多个奶蛙。
 */
@RestController
@RequestMapping("/api/naiwa")
@CrossOrigin(origins = "*")
public class NaiwaController {

    private static final String EXE_NAME = "奶蛙桌宠.exe";

    /** 默认路径：springBootTest 工作目录的上一级 /naiwa，可用配置覆盖 */
    @Value("${naiwa.exe-path:../naiwa/奶蛙桌宠.exe}")
    private String exePath;

    /**
     * POST /api/naiwa/start
     * 启动桌宠；若已在运行则直接返回，不重复启动。
     */
    @PostMapping("/start")
    public Result<Map<String, Object>> start() {
        File exe = new File(exePath);
        if (!exe.isAbsolute()) {
            exe = new File(System.getProperty("user.dir"), exePath);
        }
        exe = exe.getAbsoluteFile();

        if (!exe.isFile()) {
            return Result.fail(404, "未找到奶蛙桌宠程序：" + exe.getAbsolutePath());
        }

        Long runningPid = findRunningPid();
        if (runningPid != null) {
            return Result.ok("奶蛙桌宠已经在运行",
                    Map.of("pid", runningPid, "started", false, "path", exe.getAbsolutePath()));
        }

        try {
            ProcessBuilder builder = new ProcessBuilder(exe.getAbsolutePath());
            builder.directory(exe.getParentFile());
            builder.redirectErrorStream(true);
            Process process = builder.start();
            long pid = process.pid();

            // 给桌宠一点初始化时间；如果立刻退出说明素材或运行环境有问题
            try {
                Thread.sleep(400);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            if (!process.isAlive()) {
                return Result.fail(500, "奶蛙桌宠启动后立即退出，请检查素材文件是否齐全");
            }

            return Result.ok("奶蛙桌宠已启动",
                    Map.of("pid", pid, "started", true, "path", exe.getAbsolutePath()));
        } catch (IOException e) {
            return Result.fail(500, "启动奶蛙桌宠失败：" + e.getMessage());
        }
    }

    /** 按进程名判断是否已有奶蛙在运行，避免重复启动 */
    private Long findRunningPid() {
        String target = EXE_NAME.toLowerCase(Locale.ROOT);
        return ProcessHandle.allProcesses()
                .filter(process -> process.info().command()
                        .orElse("")
                        .toLowerCase(Locale.ROOT)
                        .contains(target))
                .map(ProcessHandle::pid)
                .findFirst()
                .orElse(null);
    }
}
