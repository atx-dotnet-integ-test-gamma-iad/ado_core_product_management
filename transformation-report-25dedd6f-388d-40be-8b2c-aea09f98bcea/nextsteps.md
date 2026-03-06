# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a clean restore to confirm all NuGet packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback and may not behave correctly at runtime.

## 3. Build the Solution

Perform a full build to confirm no errors surface outside of the IDE:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform-compatibility analyzer warnings (`CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate APIs that behaved differently under .NET Framework and now behave differently under cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer if you have not already done so. Build with the following property set to surface platform-specific API calls:

```bash
dotnet build -p:PlatformTarget=AnyCPU
```

Additionally, search the codebase for usage of APIs known to be Windows-only, such as:

- `System.Windows.Forms`
- `Microsoft.Win32.Registry`
- `System.Drawing` (GDI+ based)
- COM interop calls

If any are found, evaluate whether a cross-platform alternative exists or whether the code path needs to be conditionally compiled using `RuntimeInformation.IsOSPlatform`.

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent, and that `ConfigurationManager` calls have been updated to use `Microsoft.Extensions.Configuration` where appropriate.

## 7. Test on Target Platforms

Run the application on each operating system you intend to support (Windows, Linux, macOS) to catch any runtime behavior differences that static analysis may not surface:

```bash
dotnet run --configuration Release
```

Pay attention to:

- File path separator differences (`\` vs `/`)
- Case sensitivity of the file system on Linux
- Environment variable availability

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your deployment target. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the publish output directory to confirm all required assets are present before deploying.