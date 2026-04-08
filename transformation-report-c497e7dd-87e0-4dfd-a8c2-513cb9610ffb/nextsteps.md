# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support .NET Framework with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review the output for warnings, particularly around obsolete APIs or platform-specific code paths that may not behave correctly on non-Windows systems.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET, such as changes in globalization, reflection, or serialization behavior.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to inspect include:

- `System.Web` usage (not available in modern .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server code
- `AppDomain.CreateDomain` calls
- Binary serialization using `BinaryFormatter` (deprecated and disabled by default)

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and case-sensitive file systems on Linux.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets are present before deploying to the target environment.