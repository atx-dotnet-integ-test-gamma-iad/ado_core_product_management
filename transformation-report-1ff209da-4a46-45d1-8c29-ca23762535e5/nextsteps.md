# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no legacy TFMs such as `net472` or `net48` remain unless you are intentionally multi-targeting.

## 2. Restore Dependencies

Run the following command from the solution root to restore all NuGet packages:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been deprecated.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility that may appear at this stage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. Failures at this stage may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that are Windows-only or otherwise platform-restricted. Common areas to inspect include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (requires additional packages on Linux/macOS)
- COM interop

If any such APIs are found, either replace them with cross-platform alternatives or add a runtime platform guard.

## 6. Verify Configuration and App Settings

Confirm that any configuration files have been migrated from `App.config` or `Web.config` to the appropriate format:

- Console or class library projects: `appsettings.json` with `Microsoft.Extensions.Configuration`
- The `ConfigurationManager` API is available via the `System.Configuration.ConfigurationManager` NuGet package if a full migration is not yet feasible

## 7. Validate Runtime Behavior

Run the application manually against representative inputs or scenarios to confirm that output and behavior match the legacy version. Pay particular attention to:

- Culture-sensitive string operations, as default culture handling changed in .NET Core and later
- Serialization and deserialization, particularly with `BinaryFormatter` which is disabled by default
- Thread scheduling and `Task` behavior differences

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (RID) as needed:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Common runtime identifiers include `win-x64`, `linux-x64`, and `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the publish output directory to confirm all required assets and dependencies are present before deploying to the target environment.