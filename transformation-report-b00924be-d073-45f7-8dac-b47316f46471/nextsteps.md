# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any Windows-only packages with cross-platform equivalents if necessary.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable on non-Windows platforms. Review the code for usage of the following:

- `System.Windows.Forms` or `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `AppDomain` APIs that have been removed or restricted
- `BinaryFormatter`, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific dependencies.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required files are present.

## 8. Review Configuration Files

Ensure that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or environment-based configuration, as the legacy configuration system has limited support in modern .NET.