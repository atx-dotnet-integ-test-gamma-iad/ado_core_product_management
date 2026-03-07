# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may behave differently or are unavailable on non-Windows platforms. Run the following if the analyzer is installed:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references, which are not fully cross-platform.
- Registry access (`Microsoft.Win32.Registry`).
- File path assumptions using backslashes.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. Replace `<runtime-identifier>` with the appropriate value (e.g., `win-x64`, `linux-x64`, `osx-x64`):

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true -o ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present.

## 8. Review Configuration Files

Ensure that any `App.config` or `Web.config` files from the legacy project have been migrated to `appsettings.json` or environment-based configuration where applicable. The legacy XML-based configuration system has limited support in modern .NET.