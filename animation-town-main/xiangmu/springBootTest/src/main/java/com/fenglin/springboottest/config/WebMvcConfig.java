package com.fenglin.springboottest.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

/**
 * 静态资源映射：把上传的头像等文件目录映射为可访问的 URL。
 * 上传目录位于项目根目录下的 uploads/，映射到 /uploads/**。
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    /** 上传文件的磁盘根目录（相对项目运行目录），与 UserProfileController 保持一致 */
    public static final String UPLOAD_DIR = "uploads";

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 将 uploads/ 磁盘目录映射到 /uploads/** 访问路径
        String absolutePath = Paths.get(UPLOAD_DIR).toAbsolutePath().toString();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + absolutePath + "/");
    }
}
