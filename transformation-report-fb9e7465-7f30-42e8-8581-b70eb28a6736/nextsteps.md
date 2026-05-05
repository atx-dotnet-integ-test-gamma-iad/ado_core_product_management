# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility issues at runtime.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failing tests. Failing tests after migration commonly indicate:
- Platform-specific API usage that no longer behaves the same way on cross-platform .NET.
- Configuration or file path assumptions tied to Windows conventions.

## 5. Check for Runtime Dependencies

Inspect the code for any usage of the following, which are common sources of cross-platform runtime failures even when the build succeeds:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or is unsupported on non-Windows).
- Windows registry access via `Microsoft.Win32.Registry`.
- Hardcoded Windows-style file paths using backslashes (`\`). Replace with `Path.Combine()` or forward slashes.
- COM interop or P/Invoke calls targeting Windows-only native libraries.

## 6. Validate Configuration Files

Check that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in modern .NET.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).